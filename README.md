# Inversor de Texto

Programa escrito em Assembly para um trabalho da disciplina de Organização de Computadores.
Seu funcionamento é simples: ao usuário é requisitado digitar um texto, que será invertido usando movimentações entre as variáveis, os registradores e a stack, e após isso, mostrado no console.
Adicionalmente, foi também escrito código para evitar que a tela do console feche imediatamente após o resultado da inversão ser mostrado.

### Observações
* Foi escrito em Assembly 80836.
* O Assembler escolhido para compilar o código foi o MASM32 (sigla pra Microsoft Macro Assembler), afim de utilizar-se das funções relacionadas ao console disponíveis na Win32 API.
* Para o hightlighting da sintaxe dentro do VSCode foi utilizada a extensão MASM do blindtiger.

### Como compilar
1. Antes de tudo, é necessário ter instalado o MASM32 SDK para ter acesso as bibliotecas assembly da Win32 API utilizadas neste projeto. Você pode baixá-lo [aqui](http://masm32.com/). A instalação é simples, e portanto você não deve ter maiores dificuldades para completá-la.
2. Já fiz um arquivo batch no projeto que aliado à uma task do VSCode vai compilar o código logo que você der build no projeto.
3. Caso você não queira instalar o VSCode só para utilizar a task, basta abrir uma janela de comando na pasta do projeto, e usar os seguintes comandos:
    1. Utilize `\masm32\bin\ml /c /Zd /coff main.asm` para gerar o código de máquina a partir da source assembly. [Referência dos parâmetros utilizados](https://docs.microsoft.com/en-us/cpp/assembler/masm/ml-and-ml64-command-line-reference?view=vs-2019).
    2. Use `\masm32\bin\Link /SUBSYSTEM:CONSOLE main.obj` para gerar um arquivo EXE em sistema de console a partir do código de máquina produzido pelo passo anterior.
    3. Se tudo der certo, um EXE aparecerá na pasta do projeto.
