\masm32\bin\ml /c /Zd /coff %1.asm
\masm32\bin\Link /SUBSYSTEM:CONSOLE %1.obj
%1.exe