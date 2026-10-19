from pathlib import Path
import argparse
import re
import shutil
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

ROOT = Path(__file__).resolve().parents[2]
BUILD = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description='将作业 Markdown 排版为 PDF，自动调用 XeLaTeX 编译两次。')
parser.add_argument('--source', type=Path, default=ROOT / 'mathhw2/paper2a.md', help='输入 Markdown 文件；默认读取项目目录中的 paper1b.md')
parser.add_argument('--output', type=Path, help='输出 PDF 路径；默认 output/pdf/输入文件名.pdf')
parser.add_argument('--xelatex', default=shutil.which('xelatex'), help='xelatex.exe 的完整路径；默认从 PATH 查找')
parser.add_argument('--tex-only', action='store_true', help='只生成 LaTeX 源文件，不编译 PDF')
parser.add_argument('--no-compact-code', action='store_true', help='保持代码原有换行，不合并短表达式')
args = parser.parse_args()
source = args.source.resolve()
output = (args.output or ROOT / 'output' / 'pdf' / (source.stem + '.pdf')).resolve()
if not source.is_file():
    parser.error(f'找不到输入文件：{source}')
if not args.tex_only and not args.xelatex:
    parser.error('找不到 XeLaTeX。请使用 --xelatex 指定 xelatex.exe 的完整路径。')
text = source.read_text(encoding='utf-8-sig')

def escape(s):
    return ''.join({'\\': r'\textbackslash{}', '&': r'\&', '%': r'\%', '$': r'\$', '#': r'\#', '_': r'\_', '{': r'\{', '}': r'\}', '~': r'\textasciitilde{}', '^': r'\textasciicircum{}'}.get(c,c) for c in s)

def inline(s):
    chunks = re.split(r'(\$[^$]+\$|`[^`]+`|\*\*.+?\*\*)', s)
    out=[]
    for c in chunks:
        if c.startswith('$') and c.endswith('$'): out.append(c)
        elif c.startswith('`') and c.endswith('`'): out.append(r'\texttt{' + escape(c[1:-1]) + '}')
        elif c.startswith('**') and c.endswith('**'): out.append(r'\textbf{' + inline(c[2:-2]) + '}')
        else: out.append(escape(c))
    return ''.join(out)

preamble = r'''\documentclass[UTF8,a4paper,zihao=5,fontset=windows]{ctexart}
\usepackage[left=22mm,right=22mm,top=20mm,bottom=21mm,headheight=14pt,headsep=6mm,footskip=11mm]{geometry}
\usepackage{amsmath,amssymb,graphicx,booktabs,array,enumitem,fvextra,needspace,fancyhdr,lastpage,xcolor,hyperref}
\setmainfont{Times New Roman}
\setmonofont{Consolas}
\linespread{1}
\definecolor{ink}{HTML}{222222}
\definecolor{muted}{HTML}{666666}
\color{ink}
\hypersetup{hidelinks,pdftitle={数值积分},pdfauthor={}}
\ctexset{section={format=\heiti\fontsize{14}{19}\selectfont,beforeskip=13pt,afterskip=7pt},subsection={format=\heiti\fontsize{11.5}{16}\selectfont,beforeskip=10pt,afterskip=5pt},subsubsection={format=\heiti\fontsize{10.5}{15}\selectfont,beforeskip=8pt,afterskip=4pt}}
\setlength{\parindent}{2em}
\setlength{\parskip}{3.5pt}
\setlength{\abovedisplayskip}{7pt plus 1pt minus 1pt}
\setlength{\belowdisplayskip}{7pt plus 1pt minus 1pt}
\setlength{\abovedisplayshortskip}{4pt}
\setlength{\belowdisplayshortskip}{5pt}
\setlist[enumerate]{leftmargin=2.4em,itemsep=1pt,parsep=0pt,topsep=4pt}
\setlist[itemize]{leftmargin=2.4em,itemsep=1pt,parsep=0pt,topsep=4pt}
\pagestyle{fancy}
\fancyhf{}
\fancyhead[L]{\fontsize{8}{10}\selectfont\color{muted}高等数值计算方法实验}
\fancyhead[R]{\fontsize{8}{10}\selectfont\color{muted}数值积分}
\fancyfoot[C]{\fontsize{9}{11}\selectfont\color{muted}\thepage\ /\ \pageref*{LastPage}}
\renewcommand{\headrulewidth}{0.3pt}
\renewcommand{\footrulewidth}{0pt}
\raggedbottom
\emergencystretch=2em
\clubpenalty=10000
\widowpenalty=10000
\displaywidowpenalty=10000
\fvset{fontsize=\fontsize{8.5}{10.7}\selectfont,breaklines=true,breakanywhere=true,tabsize=4,xleftmargin=9pt,xrightmargin=3pt,framesep=5pt,rulecolor=\color{black!20},frame=leftline}
\begin{document}
\fontsize{10.5}{15.5}\selectfont
\begin{center}
{\heiti\fontsize{17}{23}\selectfont 数值积分}\par
\vspace{4pt}
{\fontsize{10}{14}\selectfont 高等数值计算方法实验报告\quad 作业 2A}
\end{center}
\vspace{2pt}
'''

lines=text.splitlines()
body=[]
i=0
pending_caption=None
while i<len(lines):
    line=lines[i].strip()
    if not line or line=='---': i+=1; continue
    if line.startswith('```'):
        language=line[3:].strip(); code=[]; i+=1
        while i<len(lines) and not lines[i].strip().startswith('```'):
            code.append(lines[i].rstrip()); i+=1
        # 合并短的多行表达式，保留全部程序语句与说明性注释。
        if language=='julia' and not args.no_compact_code:
            compact=[]
            j=0
            while j<len(code):
                c=code[j]
                if not c.strip() or re.fullmatch(r'\s*#\s*[=-]+',c): j+=1;continue
                if (c.startswith('function ') or re.match(r'# \d+\.',c)) and compact and compact[-1]!='': compact.append('')
                def balance(s):
                    s=re.sub(r'"(?:\\.|[^"\\])*"','""',s)
                    return s.count('(')+s.count('[')-s.count(')')-s.count(']')
                if not c.lstrip().startswith('#') and (balance(c)>0 or c.rstrip().endswith('=')):
                    group=[c]; k=j+1
                    while k<len(code) and (balance(' '.join(group))>0 or len(group)==1):
                        group.append(code[k]);k+=1
                    merged=group[0].rstrip()+' '+' '.join(s.strip() for s in group[1:] if s.strip())
                    if len(merged)<=95 and not any('#' in s for s in group):
                        compact.append(merged);j=k;continue
                compact.append(c);j+=1
            code=compact
        snippet=r'\par\vspace{3pt}'+'\n'+r'\begin{Verbatim}'+'\n'+'\n'.join(code)+'\n'+r'\end{Verbatim}'+'\n'+r'\vspace{3pt}'
        if language!='julia':
            snippet=r'\noindent\begin{minipage}{\linewidth}'+'\n'+snippet+'\n'+r'\end{minipage}\par'
        body.append(snippet)
        i+=1
        continue

    if line=='$$':
        math=[]
        i+=1
        while i<len(lines) and lines[i].strip()!='$$':
            math.append(lines[i])
            i+=1
        body.append('\\[\n'+'\n'.join(math)+'\n\\]')
        i+=1
        continue

    heading=re.match(r'^(#{2,4})\s+(.+)',line)
    if heading:
        level={2:'section',3:'subsection',4:'subsubsection'}[len(heading[1])]
        keep=12 if heading[2].startswith(('3.1','3.2','5.1','5.2')) else 4
        body.append(r'\Needspace{'+str(keep)+r'\baselineskip}'+'\\'+level+'*{'+inline(heading[2])+'}')
        i+=1
        continue

    if line.startswith('**图') and line.endswith('**'):
        pending_caption=line[2:-2]
        i+=1
        continue

    img=re.fullmatch(r'!\[[^\]]*\]\(([^)]+)\)',line)
    if img:
        image_path=(source.parent/img[1]).resolve()
        if not image_path.is_file():
            parser.error(f'找不到图片：{image_path}')
        width='0.99' if image_path.name=='1a.png' else '0.70'
        group=r'\par\vspace{4pt}\noindent\begin{minipage}{\linewidth}\centering'+'\n'
        group+=r'\includegraphics[width='+width+r'\linewidth]{'+image_path.as_posix()+'}'+r'\par'+'\n'
        if pending_caption:
            group+=r'\vspace{5pt}{\fontsize{9.5}{13}\selectfont '+inline(pending_caption)+'}'+r'\par'+'\n'
            pending_caption=None
        group+=r'\end{minipage}\par\vspace{5pt}'
        body.append(group)
        i+=1
        continue

    if line.startswith('|'):
        rows=[]
        while i<len(lines) and lines[i].strip().startswith('|'):
            cells=[c.strip() for c in lines[i].strip().strip('|').split('|')]
            if not all(re.fullmatch(r':?-+:?',c.replace(' ','')) for c in cells):
                rows.append(cells)
            i+=1
        table=r'\par\vspace{5pt}\noindent\begin{minipage}{\linewidth}\centering\fontsize{9}{13}\selectfont\setlength{\tabcolsep}{7pt}\renewcommand{\arraystretch}{1.2}'+'\n'
        table+=r'\begin{tabular}{'+'r'*len(rows[0])+'}'+r'\toprule'+'\n'
        for j,row in enumerate(rows):
            table+=' & '.join(inline(c) for c in row)+r' \\'+'\n'
            if j==0:
                table+=r'\midrule'+'\n'
        table+=r'\bottomrule\end{tabular}\end{minipage}\par\vspace{5pt}'
        body.append(table)
        continue

    if re.match(r'^\d+\.\s',line):
        body.append(r'\begin{enumerate}')
        while i<len(lines) and re.match(r'^\d+\.\s',lines[i].strip()):
            body.append(r'\item '+inline(re.sub(r'^\d+\.\s+','',lines[i].strip())))
            i+=1
        body.append(r'\end{enumerate}')
        continue

    para=[line]
    i+=1
    while i<len(lines) and lines[i].strip() and not re.match(r'^(#|\$\$|```|---|!\[|\||\d+\.\s)',lines[i].strip()):
        para.append(lines[i].strip())
        i+=1
    if para[0].startswith('将其代回'):
        body.append(r'\Needspace{10\baselineskip}')
    body.append(inline(' '.join(para))+'\n')

tex=BUILD/(source.stem+'.tex')
tex.write_text(preamble+'\n\n'.join(body)+'\n\\end{document}\n',encoding='utf-8')
print(f'已生成 LaTeX：{tex}', flush=True)

if args.tex_only:
    sys.exit(0)

# 编译两次，使“当前页 / 总页数”正确显示。
for pass_number in (1,2):
    print(f'正在编译 PDF（第 {pass_number}/2 次）……', flush=True)
    log_path=BUILD/(source.stem+f'.compile-{pass_number}.txt')
    command=[args.xelatex,'-interaction=nonstopmode','-halt-on-error',
             '-file-line-error','-output-directory='+str(BUILD),str(tex)]
    try:
        with log_path.open('wb') as log_file:
            result=subprocess.run(command,cwd=source.parent,stdout=log_file,stderr=subprocess.STDOUT)
    except OSError as exc:
        parser.exit(1,f'无法启动 XeLaTeX：{exc}\n')
    if result.returncode:
        details=log_path.read_text(encoding='utf-8',errors='replace').splitlines()
        print('\n'.join(details[-25:]))
        parser.exit(1,f'编译失败，完整日志：{log_path}\n')

built_pdf=BUILD/(source.stem+'.pdf')
output.parent.mkdir(parents=True,exist_ok=True)
try:
    if built_pdf.resolve()!=output:
        shutil.copy2(built_pdf,output)
except PermissionError:
    parser.exit(1,f'无法写入 {output}。请关闭正在占用该文件的 PDF 阅读器后重试。\n')
print(f'PDF 已导出：{output}')
