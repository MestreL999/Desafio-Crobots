/* ================================================================== */
/*  SENTINELAV3.R                                                     */
/*  Robo sniper para CROBOTS (Versao Otimizada e Anti-Stuck)          */
/* ================================================================== */


/* ---------------- VARIAVEIS GLOBAIS (externas) --------------------- */

int pos;      
int dmg;      
int px, py;   
int gotpv;    


/* ==================================================================== */
main()
{
  int f;

  start();                    

  while (1) {
    f = hunt();                

    if (damage() != dmg) {
      evade();                 
    } else {
      if (f == 0)
        hop(1);                
    }
  }
}

/* ==================================================================== */
start()
{
  int tx, ty, hd;

  pos = rand(4);
  if (pos > 3)
    pos = 3;                  

  tx = cox(pos);
  ty = coy(pos);

  hd = brng(tx,ty);
  drive(hd,100);                                  
  while (dist(loc_x(),loc_y(),tx,ty) > 60) {
    if (speed() == 0) {
      hd = brng(tx,ty);
      drive(hd,100);
    }
  }

  hd = brng(tx,ty);                                
  drive(hd,25);                                    
  while (dist(loc_x(),loc_y(),tx,ty) > 15) {
    if (speed() == 0) {
      hd = brng(tx,ty);
      drive(hd,25);
    }
  }

  drive(hd,0);                                     
  dmg = damage();
  gotpv = 0;
}

/* ==================================================================== */
hop(d)
int d;
{
  int t, tx, ty, hd, d0, abort;

  d0 = damage();
  t = (pos + d) % 4;          
  tx = cox(t);
  ty = coy(t);
  abort = 0;

  /* Rota dinamica: usa brng para mirar sempre no canto correto */
  hd = brng(tx,ty);
  drive(hd,100);
  
  while (dist(loc_x(),loc_y(),tx,ty) > 60 && abort == 0) {
    if (speed() == 0) {
      if (damage() != d0) {
        abort = 1; /* Preso e tomando dano: aborta a rota para lutar/fugir */
      } else {
        hd = brng(tx,ty);
        drive(hd,100); /* Apenas empurra o obstaculo */
      }
    }
  }

  if (abort == 0) {
    hd = brng(tx,ty);
    drive(hd,25);
    while (dist(loc_x(),loc_y(),tx,ty) > 15 && abort == 0) {
      if (speed() == 0) {
        if (damage() != d0) {
          abort = 1;
        } else {
          hd = brng(tx,ty);
          drive(hd,25);
        }
      }
    }
  }

  drive(hd,0);

  if (abort == 0) {
    pos = t; /* Atualiza a posicao interna apenas se concluiu a viagem */
  }
  
  dmg = damage();
  gotpv = 0;                       
}

/* ==================================================================== */
evade()
{
  int r;
  r = rand(2);
  if (r == 0) hop(1); else hop(3);
}

/* ==================================================================== */
hunt()
{
  int base, top, dg, rg, found, d0;

  base = coa(pos);
  top = base + 90;
  dg = base;
  found = 0;
  d0 = dmg;

  while (dg <= top) {
    rg = scan(dg,10);                    
    if (rg > 0 && rg <= 700) {
      dg = fine(dg);                     
      engage(dg);                        
      found = 1;
      if (damage() != d0) return (1);                      
      dg = dg - 8;                       
      if (dg < base) dg = base;
    } else {
      dg = dg + 18;                      
    }
  }
  return (found);
}

/* ==================================================================== */
fine(dg)
int dg;
{
  int lo, hi, d, rg, first, last, hit;

  lo = dg - 10;
  hi = dg + 10;
  d = lo;
  first = -1;
  last = -1;
  hit = 0;

  while (d <= hi) {
    rg = scan(d,2);
    if (rg > 0 && rg <= 700) {
      if (first == -1) first = d;
      last = d;
      hit = 1;
    }
    d = d + 3;
  }

  if (hit == 0) return (dg);              
  return ((first + last) / 2);
}

/* ==================================================================== */
engage(dg)
int dg;
{
  int rg, tx, ty, ldx, ldy, fx, fy, fb, d0, nb;

  d0 = dmg;
  rg = scan(dg,0);

  while (rg > 0 && rg <= 700 && damage() == d0) {
    tx = loc_x() + (rg * cos(dg)) / 100000;
    ty = loc_y() + (rg * sin(dg)) / 100000;

    if (gotpv == 1) {
      ldx = tx - px;              
      ldy = ty - py;              
      fx = tx + ldx;              
      fy = ty + ldy;
    } else {
      fx = tx;                    
      fy = ty;
    }

    fb = brng(fx,fy);
    cannon(fb, dist(loc_x(),loc_y(),fx,fy));   

    px = tx;
    py = ty;
    gotpv = 1;

    rg = scan(dg,0);              

    if (rg == 0) {                
      /* Busca local ampliada (janela maior) e otimizada */
      nb = dg - 4;
      while (nb <= dg + 4 && rg == 0) {
        rg = scan(nb,1);
        if (rg > 0) dg = nb;
        nb = nb + 2;
      }
    }
  }
}

/* ==================================================================== */
brng(xx,yy)
int xx, yy;
{
  int dx, dy, sc, ang;
  sc = 100000;
  dx = xx - loc_x();
  dy = yy - loc_y();
  if (dx == 0) {
    if (dy >= 0) return (90);
    return (270);
  }
  ang = atan((sc * dy) / dx);
  if (dx > 0) {
    if (ang < 0) ang = ang + 360;
    return (ang);
  }
  return (ang + 180);
}

/* ==================================================================== */
dist(x1,y1,x2,y2)
int x1,y1,x2,y2;
{
  int ddx, ddy;
  ddx = x1 - x2;
  ddy = y1 - y2;
  return (sqrt((ddx * ddx) + (ddy * ddy)));
}

/* ==================================================================== */
cox(i)
int i;
{
  if (i == 0) return (50);
  if (i == 1) return (50);
  if (i == 2) return (950);
  return (950);
}

coy(i)
int i;
{
  if (i == 0) return (50);
  if (i == 1) return (950);
  if (i == 2) return (950);
  return (50);
}

coa(i)
int i;
{
  if (i == 0) return (0);
  if (i == 1) return (270);
  if (i == 2) return (180);
  return (90);
}

/* fim de sentinelav3.r */
