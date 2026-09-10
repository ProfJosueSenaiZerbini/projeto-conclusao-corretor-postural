
Nome dos Integrantes:

Bruno Eduardo dos Santos
Lara Beatriz Freitas de Alencar
Gabriel Henrique Pereira
Gabriel Candido
Victor Cruz


O projeto consiste no desenvolvimento de uma plataforma integrada de hardware e software baseada em Internet das Coisas Médicas (IoMT) voltada para a saúde preventiva e ergonomia no ambiente de trabalho.

1. Qual problema o projeto resolve?A expansão do teletrabalho (home office) sem mobiliário adequado expõe profissionais a riscos ergonômicos crônicos, resultando em Lesões por Esforços Repetitivos (LER) e Distúrbios Osteomusculares Relacionados ao Trabalho (DORT). O projeto busca mitigar a ocorrência de posturas inadequadas e fornecer dados analíticos para a gestão da saúde ocupacional.
2. Qual é o objetivo principal?Monitorar a postura do usuário em tempo real, emitir alertas corretivos imediatos e tabular os dados para acompanhamento estatístico.
3. Como a solução é constituída?Hardware (Wearable Vestível): Um dispositivo físico equipado com um microcontrolador ESP32 e sensor MPU6050 (acelerômetro/giroscópio) que detecta a inclinação da coluna e aciona um mini motor de vibração para dar feedback tátil corretivo ao usuário.  Software e APIs: Uma API REST em Node.js integrada a um banco de dados MySQL, desenvolvida com autenticação segura JWT e em conformidade com a LGPD.  Interfaces (Dashboards): Aplicativos mobile e web desenvolvidos em Flutter e React, com telas e acessos distintos para que tanto usuários quanto médicos possam acompanhar a evolução e os relatórios estatísticos da postura.  
