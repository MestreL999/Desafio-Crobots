/* ================================================================== */
/*  SENTINELAV3_EXPLICADO.R                                           */
/*  Robo sniper para CROBOTS (Versao Otimizada e Anti-Stuck)          */
/*  COM COMENTARIOS PASSO A PASSO                                     */
/* ================================================================== */

/* ---------------- VARIAVEIS GLOBAIS (externas) --------------------- */
/* Estas variaveis mantem seus valores durante toda a partida.         */

int pos;      /* Armazena o canto atual do robo (0=SO, 1=NO, 2=NE, 3=SE). */
int dmg;      /* Armazena a saude/dano atual. Usado para saber se tomou tiro. */
int px, py;   /* Posicao X e Y do inimigo na ULTIMA vez que o vimos. */
int gotpv;    /* Flag (0 ou 1) que diz se px e py tem valores validos para prever o movimento do alvo. */

/* ==================================================================== */
/* main()                                                               */
/* Ponto de entrada do programa. O laco principal (loop) da IA.         */
/* ==================================================================== */
main()
{
  int f;

  start(); /* 1. Inicializa o robo e corre para um dos 4 cantos seguros do mapa. */

  while (1) { /* 2. Loop infinito: o cerebro do robo roda sem parar aqui ate a partida acabar. */
    
    f = hunt(); /* 3. Modo de caca: varre o cenario. Se achar algo, atira. Retorna 1 se engajou, 0 se vazio. */

    if (damage() != dmg) {
      /* 4. Checagem de sobrevivencia: se o dano mudou desde a ultima checagem, fomos atingidos. */
      evade(); /* 5. Inicia manobra de fuga imediata. */
    } else {
      if (f == 0)
        /* 6. Se o setor esta vazio (f==0) e nao estamos sob ataque... */
        hop(1); /* 7. Pula para o proximo canto para patrulhar um novo angulo. */
    }
  }
}

/* ==================================================================== */
/* start()                                                              */
/* Escolhe um canto aleatorio no inicio da partida e vai ate la.        */
/* ==================================================================== */
start()
{
  int tx, ty, hd;

  /* Sorteia um numero de 0 a 3 (representando os 4 cantos) */
  pos = rand(4);
  if (pos > 3) pos = 3; /* Margem de seguranca caso a funcao rand() falhe e retorne 4 */

  /* Pega as coordenadas X (tx) e Y (ty) do canto sorteado nas funcoes cox e coy (la embaixo) */
  tx = cox(pos);
  ty = coy(pos);

  /* Calcula o grau/rumo (hd = heading) da nossa posicao atual ate o canto destino */
  hd = brng(tx,ty);
  drive(hd,100); /* Acelera o motor na velocidade maxima (100) na direcao do canto */
  
  /* Continua acelerando enquanto estiver longe (> 60 unidades) do canto */
  while (dist(loc_x(),loc_y(),tx,ty) > 60) {
    if (speed() == 0) {
      /* Anti-Stuck: Se o robo bateu em algo e a velocidade zerou, recalcula a rota e arranca de novo */
      hd = brng(tx,ty);
      drive(hd,100);
    }
  }

  /* Quando chega perto (<= 60), recalcula a rota para alinhar perfeitamente ao ponto final */
  hd = brng(tx,ty);                                
  drive(hd,25); /* Reduz a velocidade para 25 para nao bater com forca na quina */
  
  /* Freio gradual: vai devagar ate chegar a 15 unidades do alvo (frenagem antecipada) */
  while (dist(loc_x(),loc_y(),tx,ty) > 15) {
    if (speed() == 0) {
      hd = brng(tx,ty);
      drive(hd,25);
    }
  }

  drive(hd,0); /* Chegamos! Manda o motor parar (velocidade 0). O deslizamento nos coloca em 50x50. */
  dmg = damage(); /* Salva como nossa saude (dano atual) esta agora. */
  gotpv = 0; /* Limpa a memoria de alvos (ainda nao vimos ninguem). */
}

/* ==================================================================== */
/* hop(d)                                                               */
/* Deslocamento tactico. Pula do canto atual para um vizinho pelas bordas. */
/* ==================================================================== */
hop(d)
int d;
{
  int t, tx, ty, hd, d0, abort;

  d0 = damage(); /* Salva a vida no momento que comecou a pular */
  t = (pos + d) % 4; /* Calcula qual o proximo canto de forma circular (Ex: de 3 vai pro 0) */
  tx = cox(t);
  ty = coy(t);
  abort = 0; /* Controle de interrupcao (0 = viagem tranquila, 1 = deu problema na rota) */

  /* Rota dinamica: usa a funcao brng() em vez de angulos duros (0, 90...) para corrigir desvios no trajeto */
  hd = brng(tx,ty);
  drive(hd,100); /* Arranca pelas paredes a 100% de velocidade */
  
  while (dist(loc_x(),loc_y(),tx,ty) > 60 && abort == 0) {
    /* Sistema Anti-Stuck + Evasao sob fogo cruzado */
    if (speed() == 0) { /* Velocidade 0 significa que batemos fisicamente em uma parede ou inimigo */
      if (damage() != d0) { 
        /* Se travamos E levamos dano: ativa a flag para abortar a patrulha. Hora de se defender ou fugir. */
        abort = 1; 
      } else {
        /* Se travamos MAS nao levamos tiro: e so outro robo burro no caminho. Refaz a rota e "empurra" ele a 100%. */
        hd = brng(tx,ty);
        drive(hd,100); 
      }
    }
  }

  /* Fase de frenagem final (se ninguem atrapalhou a corrida) */
  if (abort == 0) {
    hd = brng(tx,ty);
    drive(hd,25); /* Vai devagar (25%) para entrar na vaga sem amassar a lataria */
    while (dist(loc_x(),loc_y(),tx,ty) > 15 && abort == 0) {
      if (speed() == 0) {
        if (damage() != d0) abort = 1;
        else { hd = brng(tx,ty); drive(hd,25); }
      }
    }
  }

  drive(hd,0); /* Estaciona */

  if (abort == 0) {
    pos = t; /* Se a viagem foi concluida com sucesso, atualiza o 'pos' para o novo canto */
  }
  
  dmg = damage(); /* Atualiza nosso banco de vida */
  gotpv = 0; /* Limpa a memoria de mira (o angulo anterior nao serve mais neste novo canto) */
}

/* ==================================================================== */
/* evade()                                                              */
/* Fuga aleatoria. 50% de chance de correr pra direita, 50% pra esq.    */
/* ==================================================================== */
evade()
{
  int r;
  r = rand(2);
  if (r == 0) hop(1); else hop(3);
}

/* ==================================================================== */
/* hunt()                                                               */
/* Radar primario. Faz a varredura inicial em busca de inimigos.        */
/* ==================================================================== */
hunt()
{
  int base, top, dg, rg, found, d0;

  base = coa(pos); /* Consulta coa() para saber o angulo inicial deste canto especifico */
  top = base + 90; /* Varre 90 graus (o suficiente para cobrir toda a arena partindo de uma quina) */
  dg = base;
  found = 0; /* Status: encontrou alvo? Falso. */
  d0 = dmg;

  while (dg <= top) {
    rg = scan(dg,10); /* Radar "grosseiro": feixe largo de 10 graus. Pega de tudo. */
    
    /* rg e a distancia. Maior que 0 (nao e parede) e menor que 700 (alcance de visao/tiro) */
    if (rg > 0 && rg <= 700) {
      dg = fine(dg); /* Achou! Ativa o radar fino para pegar a coordenada central exata. */                     
      engage(dg);    /* Trava a mira e comeca a atirar pre-calculando o futuro! */                    
      found = 1;     /* Registra que encontramos alguem. */
      
      /* Se tomamos tiro enquanto fuzilavamos o cara, avisa o sistema (retorna 1) pra iniciar a fuga (evade) */
      if (damage() != d0) return (1);                      
      
      dg = dg - 8; /* Recuo tactico: volta a mira em 8 graus para ver se o alvo escorregou pra tras */                     
      if (dg < base) dg = base; /* Nao deixa o radar girar e olhar pra fora do limite da arena */
    } else {
      dg = dg + 18; /* Se o setor de 10 graus tava limpo, pula +18 graus pra olhar a proxima fatia de pizza. */                     
    }
  }
  return (found); /* Devolve se houve ou nao engajamento */
}

/* ==================================================================== */
/* fine(dg)                                                             */
/* Radar secundario de alta precisao (+- 2 graus de resolucao).         */
/* ==================================================================== */
fine(dg)
int dg;
{
  int lo, hi, d, rg, first, last, hit;

  lo = dg - 10; /* Vai 10 graus para a esquerda do vulto que vimos */
  hi = dg + 10; /* E vai buscar ate 10 graus para a direita */
  d = lo;
  first = -1; /* Ponto da primeira "esbarrada" no alvo */
  last = -1;  /* Ponto da ultima "esbarrada" */
  hit = 0;

  while (d <= hi) {
    rg = scan(d,2); /* Feixe fino. */
    if (rg > 0 && rg <= 700) {
      if (first == -1) first = d; /* Marca a borda esquerda do alvo quando detectar. */
      last = d; /* Vai atualizando a borda direita conforme varre por cima dele. */
      hit = 1;
    }
    d = d + 3; /* Avanca passo a passo. */
  }

  if (hit == 0) return (dg); /* Se o alvo piscou e sumiu como um fantasma, devolve o angulo cego original */             
  
  /* PONTO VITAL DA ESTRATEGIA: Atira no CENTRO. (Primeira Borda + Ultima Borda) / 2.
     Garante que mesmo que o alvo ande, ele leve o tiro grosso. */
  return ((first + last) / 2); 
}

/* ==================================================================== */
/* engage(dg)                                                           */
/* Sistema de tiro preditivo (Sniper). Calcula velocidade pelo delta.   */
/* ==================================================================== */
engage(dg)
int dg;
{
  int rg, tx, ty, ldx, ldy, fx, fy, fb, d0, nb;

  d0 = dmg;
  rg = scan(dg,0); /* "Lock On" militar: feixe em zero (linha reta pura) focada no alvo. */

  /* Enquanto o alvo tiver na mira E nao estivermos apanhando... */
  while (rg > 0 && rg <= 700 && damage() == d0) {
    
    /* A linguagem nao te da a coordenada (X,Y) do inimigo, entao calculamos com trigonometria: 
       Posicao Real Inimigo = Minha Posicao + (Distancia * Seno/Cosseno do Angulo da Mira) */
    tx = loc_x() + (rg * cos(dg)) / 100000;
    ty = loc_y() + (rg * sin(dg)) / 100000;

    if (gotpv == 1) {
      /* CALCULO DE TRAJETORIA (Predicao) */
      ldx = tx - px; /* Velocidade Vetorial X: Posicao atual X - Posicao do ultimo tiro X */              
      ldy = ty - py; /* Velocidade Vetorial Y */              
      
      fx = tx + ldx; /* Ponto futuro (Future X): Onde ele provavelmente estara no instante que a bala chegar. */              
      fy = ty + ldy; 
    } else {
      /* Primeiro tiro na pessoa: nao sabemos pra onde ela ta correndo ainda. Atira nela mesma. */
      fx = tx;                    
      fy = ty;
    }

    fb = brng(fx,fy); /* Calcula o angulo da nossa cabeca de tiro ate o ponto futuro */
    cannon(fb, dist(loc_x(),loc_y(),fx,fy)); /* Fogo! (Passando o angulo e a distancia do disparo) */   

    /* Salva o "agora" para ser o "passado" da proxima volta do loop (usado pra calcular ldx/ldy) */
    px = tx;
    py = ty;
    gotpv = 1;

    rg = scan(dg,0); /* Checa se o infeliz continua preso no nosso raio trator de 0 graus. */

    if (rg == 0) {                
      /* Busca em curto espaco de tempo: se o alvo deu um toquinho pro lado pra tentar desviar */
      nb = dg - 4; /* Abre uma janelinha de 8 graus (+-4) */
      while (nb <= dg + 4 && rg == 0) {
        rg = scan(nb,1); /* Se mover o radar 1 grauzinho ele ta la? */
        if (rg > 0) dg = nb; /* Recapturado! Arruma a variavel global e o laco continua. */
        nb = nb + 2;
      }
    }
  }
}

/* ==================================================================== */
/* FUNCOES MATEMATICAS AUXILIARES                                       */
/* ==================================================================== */

/* brng(xx,yy): Bearing (Direcao). Descobre para qual grau o robo tem 
   que virar para olhar para as coordenadas X e Y passadas. Usa arco-tangente (atan). */
brng(xx,yy)
int xx, yy;
{
  int dx, dy, sc, ang;
  sc = 100000;
  dx = xx - loc_x();
  dy = yy - loc_y();
  
  if (dx == 0) { /* Evita divisao por zero */
    if (dy >= 0) return (90);
    return (270);
  }
  
  ang = atan((sc * dy) / dx);
  
  if (dx > 0) { /* Ajuste de quadrantes cartesianos para o arco-tangente */
    if (ang < 0) ang = ang + 360;
    return (ang);
  }
  return (ang + 180);
}

/* dist(x1,y1,x2,y2): Distancia. Aplica o Teorema de Pitagoras puro. */
dist(x1,y1,x2,y2)
int x1,y1,x2,y2;
{
  int ddx, ddy;
  ddx = x1 - x2;
  ddy = y1 - y2;
  return (sqrt((ddx * ddx) + (ddy * ddy)));
}

/* ==================================================================== */
/* coa(i), cox(i), coy(i): Arrays Simulados.                            */
/* C nao suportava matrizes nativas na versao enxuta do CROBOTS,        */
/* entao funcoes com ifs servem como indices de memoria.                */
/* ==================================================================== */

/* coa (Corner Angle): Para onde o radar aponta baseado no canto (0-90-180-270) */
coa(i) int i; {
  if (i == 0) return (0);   /* Sudoeste olha para o Leste e sobe pra fechar os 90 */
  if (i == 1) return (270); /* Noroeste olha para o Sul e vai a Leste */
  if (i == 2) return (180); /* Nordeste olha para o Oeste e desce para o Sul */
  return (90);              /* Sudeste olha para o Norte e vai para o Oeste */
}

/* cox (Corner X): Coordenada X (Segura e recuada com 50 e 950 para nao bater na borda 0) */
cox(i) int i; {
  if (i == 0) return (50);  /* SO */
  if (i == 1) return (50);  /* NO */
  if (i == 2) return (950); /* NE */
  return (950);             /* SE */
}

/* coy (Corner Y): Coordenada Y (Segura) */
coy(i) int i; {
  if (i == 0) return (50);  /* SO */
  if (i == 1) return (950); /* NO */
  if (i == 2) return (950); /* NE */
  return (50);              /* SE */
}
/* fim de sentinelav3_explicado.r */
