pragma solidity ^0.4.24;

//Presenca foi implementada como um contrato de tokens, de forma similar a especificada
//na ERC-20 -> https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
//Foram omitidas as funcoes approve e allowance
contract Presenca {
    
	  // Array com todos os 'saldos' (balances)
    mapping (address => uint128) presencas;
    
    event Transfer(address indexed remetente, address indexed destinatario, uint128 quantidade);
    
    //todos os tokens ficam inicialmente com a entidade (universidade)
    function Presenca(uint128 inicial) {presencas[msg.sender] = inicial;}
    
    //faz o papel da funcao balanceOf
    function presencaDe(address estudante) public view returns (uint128 saldo) {
        return presencas[estudante];
    }
    
    // Faz o papel da funcao 'transfer'
    function chamada(address estudante, uint8 quantidade) public returns(bool success) {
        require(presencas[msg.sender] >= quantidade);					      //verifica se restam tokens para serem enviados
        assert (presencas[estudante] + quantidade >= quantidade);		//verifica possibilidade de overflow
        presencas[msg.sender] -= quantidade;							          //retira do saldo do remetente (universidade)
        presencas[estudante] += quantidade;							            //'deposita' no saldo do destinatário (estudante)
        emit Transfer(msg.sender, estudante, quantidade);           //registra o evento de transferencia
        return true;
    }
    
    function transferFrom(address remetente, address destinatario, uint128 quantidade) public returns(bool success) {
        require(presencas[remetente] >= quantidade);
        presencas[remetente] -= quantidade;
        presencas[destinatario] += quantidade;
        emit Transfer(remetente, destinatario, quantidade);
        return true;
    }
    
}


contract Disciplina {
    
    Presenca presenca;                      //Cada disciplina tem um contrato com as presencas dos estudantes
    uint8 departamento;                     //Codigo numerico para o departamento responsavel pela disciplina
    uint128 codigo;                         //Codigo numerico para a disciplina
    uint128 presenca_minima;                //Presenca minima necessaria para concluir a disciplina
    
    address[] matriculas;                   //Enderecos dos alunas matriculados na disciplina
    mapping (address => uint8) notaDe;      //Notas finais dos estudantes
    
    event DisciplinaValidada(address indexed estudante, uint8 departamento, uint128 codigo, uint8 nota_final);
    
    function Disciplina (uint8 dep, uint128 cod, uint128 minima, uint128 presenca_maxima) {
        departamento = dep;
        codigo = cod;
        presenca_minima = minima;
        
        presenca = new Presenca(presenca_maxima);
    }
    
    function chamada(address estudante, uint8 quantidade) {presenca.chamada(estudante, quantidade);}
	
	function setNota(address estudante, uint8 nota_final) {notaDe[estudante] = nota_final;}
	
	function matricula(address estudante) {matriculas.push(estudante);}
	
	function encerrarSemestre() {
	    uint256 quantidade_matriculados = matriculas.length;
	    for (uint8 i = 0; i<quantidade_matriculados; i++) {
	        address endereco_estudante = matriculas[i];
	        uint128 presenca_estudante = presenca.presencaDe(endereco_estudante);
	        presenca.transferFrom(endereco_estudante, msg.sender, presenca_estudante);                      //recolhe tokens de presenca para nao serem utilizados em semestres futuros
	        if (presenca_estudante < presenca_minima) continue;                                             //nao valida materia se presenca for inferior a minima
	        if (notaDe[endereco_estudante] < 6) continue;                                                   // nao valida materia se nota for inferior a minima
	        emit DisciplinaValidada(endereco_estudante, departamento, codigo, notaDe[endereco_estudante]);  //dada todas as condicoes cumpridas, valida a materia
	    }
	}
    
}


contract Curriculo {
    
    address[] disciplinas;
    
    event CurriculoValidado(address indexed estudante);
    
    function addDisciplina(uint8 dep, uint128 cod, uint128 pres_minima, uint128 pres_maxima) {
        address newContract = new Disciplina(dep, cod, pres_minima, pres_maxima);
        disciplinas.push(newContract);
    }
    
    
    function validaCurriculo(address estudante) {
        //A ideia aqui seria varrer os logs de eventos que contem o endereco do 
        //estudante passado por parametro para ver se todas as disciplinas do 
        //curriculo foram validadas para ele, mas nao encontrei uma maneira de fazer isso
        //via solidity em tempo.
    }
    
}
