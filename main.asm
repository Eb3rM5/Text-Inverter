.386 ;Habilita instruções não-privilegiadas de processadores 80386, porém desabilita as intruções introduzidas em processadores mais recentes
.model flat, stdcall ;Especifica os tipos de modelos de memória a serem utilizados
option casemap : none ;Torna o assembler case sensitive

;Como nas versões mais recentes do Windows não é mais possível usar o operador int para alterar o modo do console, é necessário utilizar a Win32 API caso queira-se utilizar entrada ou saída no mesmo. Dessa forma, a seguir incluímos as bibliotecas que contém as funções que precisamos.
include \masm32\include\windows.inc
include \masm32\include\kernel32.inc
includelib \masm32\lib\kernel32.lib

.data
    stdOut dd ? ;Variável que irá armazenar o HANDLE do STD_OUT do console
    stdIn dd ? ;Irá armazenar o HANDLE do STD_IN do console
    question BYTE "Digite seu texto: " ;Primeira mensagem a ser printada
    finalMessage BYTE "Seu texto invertido: " ;Segunda mensagem a ser printada
    exitMessage BYTE 13,10,"Pressione qualquer tecla para sair..." ;Mensagem que será mostrada na saída. O 13 é o valor em ASCII do caractere que retorna o cursor de texto para o início da linha, e o 10 é o valor em ASCII que coloca o cursor de texto em uma nova linha.
    messageArray db 4096 dup(?) ;Array que irá armazenar os bytes da mensagem digitada pelo usuário
    messageLength dd ? ;Armazenará a quantidade de bytes do texto que o usuário escreveu
    bytesWritten dd ? ;Armazenará quantos bytes foram escritos a cada chamada de escrita ou saída do console

.code

    main PROC

        LOCAL ir :INPUT_RECORD ;Variável local utilizada no último conjunto de instruções do programa para armazenar os dados relacionados ao evento de pressionamento de tecla produzido pela função ReadConsoleInput. Quando usado, o comando LOCAL necessita ser colocado no início de um bloco PROC, pois de outra forma o código não compilará.

        push STD_OUTPUT_HANDLE ;Armazena o valor correspondente à OUTPUT do console na stack
        call GetStdHandle ;Armazena a HANDLE correspondente ao parâmetro no registrador EAX
        mov stdOut, eax ;Move o valor armazenado no EAX para a variável stdOut

        push STD_INPUT_HANDLE ;Armazena o valor correspondente à INPUT do console na stack
        call GetStdHandle ;Armazena a HANDLE correspondente ao parâmetro no registrador EAX
        mov stdIn, eax ;Move o valor armazenado no EAX para a variável stdOut

        

        ;Aqui a função WriteConsole (documentação disponível em: https://docs.microsoft.com/en-us/windows/console/writeconsole), é utilizada para imprimir no console uma mensagem ao usuário. Porém, diferente da GetStdHandle, essa função precisa de mais de um parâmetro. Por isso, cada vez que um novo parâmetro é inserido, o operador push é utilizado para inserí-lo na stack. Começa-se do último pois a stack vai sendo "empurrada".
        push 0 ;Segundo a documentação da Microsoft, o último parâmetro deve ser sempre nulo. Como geralmente não existem declarações (statements) equivalentes à nulidade em Assemblers (o que é o caso do MASM), deve ser utilizado 0 para representá-lo
        push offset bytesWritten ;No penúltimo parâmetro deve-se indicar o endereço em relação ao começo da memória do pointer para o qual serão enviados os dados referentes a quantidade de bytes escritos no console. Tende a ser igual a quantidade de bytes da variável question, especificada a seguir
        push sizeof question ;O ante-penúltimo parâmetro indica a quantidade de bytes do texto a serem escritos. O operador sizeof é utilizado por questão de praticidade, já que ele determina a quantidade de bytes de uma variável (no caso, a variável question)
        push offset question ;O segundo parâmetro indica o endereço em relação ao começo da memória do pointer que contém os bytes do texto a ser imprimido.
        push stdOut ;O primeiro parâmetro indica o HANDLE no qual serão escritos os bytes. No caso, o HANDLE da OUTPUT do console que pegamos anteriormente é utilizado.
        call WriteConsole


        ;Aqui a função ReadConsole (documentação disponível em: https://docs.microsoft.com/en-us/windows/console/ReadConsole) é utilizada na finalidade de requirir do usuário que ele digite algum texto. Seus parâmetros são praticamente iguais aos do WriteConsole, com a diferença de que os dados serão escritos para o pointer indicado, em vez de serem lidos dele.
        push 0 
        push offset bytesWritten
        push sizeof messageArray
        push offset messageArray
        push stdIn
        call ReadConsole

        ;A seguir o operador DEC é utilizado para decrementar duas vezes a variável bytesWritten. A razão para isso é porque no momento em que o usuário tecla ENTER durante a função ReadConsole, o caractere que indica uma nova linha é inserido junto do texto. Como o mesmo pesa cerca de dois bytes, já descontamos ele aqui para evitar comportamentos estranhos ao inverter o texto.
        dec bytesWritten
        dec bytesWritten

        mov ecx, bytesWritten ;Armazena a quantidade de bytes escritos no registrador ECX
        mov esi, 0 ;Aqui o registrador de índices ESI é utilizado pela primeira vez, sendo o mesmo colocado no início da contagem.

        stackStr: ;Loop criado com a finalidade de armazenar cada byte do texto na stack
            movzx eax, messageArray[esi] ;Move o valor que está na mensageArray dentro do índice indicado, para o registrador EAX. Diferente do MOV, o MOVZX fecha a sequência de bytes em 16 ou caso necessário, 32 bits. Por consequencia os 8 bits do caractere ficarão disponíveis mais tarde no registrador AL.
            push eax ;Empurra na stack o último valor inserido no EAX
            inc esi ;Incrementa o registrador ESI
        loop stackStr

        mov ecx, bytesWritten ;Novamente insere a quantidade de bytes escritos no registrador ECX, já que a sequência anterior foi consumida durante o loop 
        mov esi, 0 ;Coloca o registrador de índices ESI novamente na primeira posição

        invert: ;Loop que vai ler os bytes armazenados na stack desde o primeiro valor empurrado nela
            pop eax ;Pega o byte que está no topo da stack
            mov messageArray[esi], al ;Aqui o registrador AL é utilizado para pegar os últimos 8 bits do valor aparecendo no EAX. A razão de somente 8 bits serem necessários é devida ao padrão ASCII/ANSI armazenar 8 bits por caractere. Dessa forma, podemos esperar que cada caractere irá ter sempre 8 bits. Como 1 byte possui 8 bits, podemos armazenar o valor pego na posição atual da array de bytes.
            inc esi ;Incrementa o registrador ESI
        loop invert

        ;As duas linhas a seguir servem para armazenar a quantidade de bytes da mensagem em outra variável, chamada messageLength, já que a variável bytesWritten será sobrescrita já nas próximas chamadas do console. A razão disso é para evitar que o programa leia todos os 4096 bytes da messageArray e imprima o texto com um grande espaço em branco após o final, já que o texto digitado pelo usuário na maioria das vezes não ocupa todo o espaço disponível na messageArray.
        mov ecx, bytesWritten
        mov messageLength, ecx

        ;Utilizamos novamente a função WriteConsole, desta vez para escrever o texto armazenado na variável finalMessage
        push 0
        push offset bytesWritten
        push sizeof finalMessage
        push offset finalMessage
        push stdOut
        call WriteConsole

        ;Utilizamos a função WriteConsole para escrever a array de bytes já invertida.
        push 0
        push offset bytesWritten
        push messageLength
        push offset messageArray
        push stdOut
        call WriteConsole

        push 0
        push offset bytesWritten
        push sizeof exitMessage
        push offset exitMessage
        push stdOut
        call WriteConsole

        .REPEAT ;Para evitar que a janela do programa se feche antes que o usuário veja o resultado da inversão, criamos um loop que irá ler a tecla que o usuário pressionou, e só irá parar quando, uma tecla for pressionda

            ;Diferente da função ReadConsole, a função ReadConsoleInput (documentação disponível em: https://docs.microsoft.com/en-us/windows/console/readconsoleinput) lê eventos de entrada (mouse, teclado, foco da janela, etc). Aqui ela é utilizada para ler eventos do teclado
            push offset bytesWritten ;Reutilizamos a variável bytesWritten para armazenar a quantidade de eventos produzidos pelo usuário
            push 1 ;Esse parâmetro se refere ao tamanho da array de eventos. Inserindo um, a função irá retornar logo que o usuário produza 1 evento.
            lea eax, ir ;Utilizamos o operador lea para armazenar no registrador EAX o endereço efetivo na memória da variável ir. Usamos ele em vez de utilizar diretamente o operador offset, pois este último só pode ser utilizado em variáveis globais, as quais já tem seu endereço na memória fixo desde o início da execução
            push eax ;Colocamos na stack o endereço anteriormente colocado no registrador EAX
            push stdIn ;Novamente, indicamos qual o HANDLE com o qual o método vai trabalhar
            call ReadConsoleInput

            movzx ecx, word ptr ir.EventType ;Colocamos no registrador ECX o tipo de evento retornado pela função ReadConsoleInput, ao mesmo tempo em que dizemos que o o pointer é do tipo WORD
        .UNTIL (ecx==KEY_EVENT) && (ecx==ir.KeyEvent.bKeyDown) ;Comparamos se o valor colocado no ECX é um evento originado do teclado, e se é um evento do tipo pressionamento. Caso seja falso, o loop continua.

        ;Finaliza o processo e sai do console
        push 0
        call ExitProcess

    main ENDP
    END main

END