unit Unit1;

{$MODE Delphi}
//{$mode objfpc}{$H+}

{ Cet ensemble de routine est extrait de mon bac à sable habituel
et rassemble ce qui est nécessaire pour comparer les extraits des
différents dicos de latin dans l'espoir d'en faire un lexique étendu
pour Collatinus.
Ce n'est sûrement pas un modèle de programmation, mais c'est le
résultat d'un développement linéaire ou presque.
Philippe Verkerk
Décembre 2014.
}
interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs;

type
  TForm1 = class(TForm)
  private
    { private declarations }
  public
    { public declarations }
  end;

const
  comb_breve=chr(204)+chr(134); // Combining breve U+0306 ou CC 86

var
  Form1: TForm1;
  fic_in,fic_out,mots,rejet:text;
  fic_ls,fic_lw,fic_gj,fic_ge,fic_fg,fic_yo,fic_po,fic_w1,fic_w2,fic_w3,fic_w4:text;
  ligne_ls,ligne_lw,ligne_gj,ligne_ge,ligne_fg,ligne_yo,ligne_po,ligne_w1,ligne_w2,ligne_w3,ligne_w4:string;
  lem_ls,lem_lw,lem_gj,lem_fg,lem_ge,lem_yo,lem_po,lem_w1,lem_w2,lem_w3,lem_w4:string;
  lg_ls,lg_lw,lg_gj,lg_ge,lg_fg,lg_yo,lg_po,lg_wh:string;
  lem_prec, lem_cour: string;
  ligne, reste : string;
  i, n, nb_mots : integer;
  lgn:array[0..4095] of string;
  // Beaucoup trop de variables globales, mais c'est pratique pour ne pas avoir
  // trop de paramètres à passer.

implementation

{$R *.lfm}

procedure lis_ls;
begin
   ligne_ls:='';
     if eof(fic_ls) then lem_ls:='zz'
        else begin
             repeat
             readln(fic_ls, ligne);
             until ((pos('|',ligne)<>0) or eof(fic_ls)) ;
             if (pos('|',ligne)=0) then lem_ls:='zz'
                else begin
                     reste:=copy(ligne,pos('|',ligne)+1,length(ligne));
//                     lem_ls:=trim(copy(reste,1,pos('|',reste)-1));
                     lem_ls:=lowercase(trim(copy(reste,1,pos('|',reste)-1)));
                     ligne_ls:=ligne;
                     end;
             end
end;

procedure lis_lw;
begin
   ligne_lw:='';
   if eof(fic_lw) then lem_lw:='zz'
        else begin
     repeat
     readln(fic_lw, ligne);
     until ((pos('|',ligne)<>0) or eof(fic_lw)) ;
     if (pos('|',ligne)=0) then lem_lw:='zz'
        else begin
             reste:=copy(ligne,pos('|',ligne)+1,length(ligne));
             lem_lw:=lowercase(trim(copy(reste,1,pos('|',reste)-1)));
             if (pos(' ',lem_lw)<>0) then lem_lw:=copy(lem_lw,1,pos(' ',lem_lw)-1);
             ligne_lw:=ligne;
             end
        end;
end;

procedure lis_yo;
begin
   ligne_yo:='';
     if eof(fic_yo) then lem_yo:='zz'
        else begin
           readln(fic_yo, ligne);
     if (pos('|',ligne)=0) then lem_yo:='zz'  // fin du fichier
        else begin
             lem_yo:=copy(ligne,1,pos('|',ligne)-1);
             ligne_yo:=ligne;
             end
        end;
end;

procedure lis_gj;
// var jj : integer;

begin
     ligne_gj:='';
     if eof(fic_gj) then lem_gj:='zz'
        else begin
     repeat
           readln(fic_gj,ligne);
     until ((length(ligne)>3) or eof(fic_gj));
             if (pos('|',ligne)>0) then lem_gj:=lowercase(copy(ligne,1,pos('|',ligne)-1))
                                 else lem_gj:='@@@';
             ligne_gj:=ligne;
        end;
end;

procedure lis_ge;

begin
     ligne_ge:='';
     if eof(fic_ge) then lem_ge:='zz'
        else begin
     repeat
           readln(fic_ge,ligne_ge);
     until ((length(ligne_ge)>3) or eof(fic_ge));
             if (pos('|',ligne_ge)>0) then
                lem_ge:=lowercase(copy(ligne_ge,1,pos('|',ligne_ge)-1))
                                 else lem_ge:='@@@';
        end;
end;

procedure lis_po;

begin
     ligne_po:='';
     if eof(fic_po) then lem_po:='zz'
        else begin
                readln(fic_po,ligne_po);
             if (pos('|',ligne_po)>0) then
                lem_po:=lowercase(copy(ligne_po,1,pos('|',ligne_po)-1))
                     else lem_po:='@@@';
        end;
end;

procedure lis_fg;
begin
   ligne_fg:='';
     if eof(fic_fg) then lem_fg:='zz'
        else begin
     repeat
     readln(fic_fg, ligne);
     until ((pos('|',ligne)<>0) or eof(fic_fg)) ;
     if (pos('|',ligne)=0) then lem_fg:='zz'
        else begin
//             lem_fg:=trim(copy(ligne,1,pos('|',ligne)-1));
             lem_fg:=lowercase(trim(copy(ligne,1,pos('|',ligne)-1)));
             if (pos(' (',lem_fg)<>0) then lem_fg:=copy(lem_fg,1,pos(' (',lem_fg)-1);
             ligne_fg:=ligne;
             end
        end;
end;

procedure lis_w1;
begin
   ligne_w1:='';
   if eof(fic_w1) then lem_w1:='zz'
      else begin
           readln(fic_w1,ligne);
//           lem_w1:=trim(copy(ligne,1,pos(',',ligne)-1));
           lem_w1:=lowercase(trim(copy(ligne,1,pos(',',ligne)-1)));
           ligne_w1:=ligne;
      end;
end;

procedure lis_w2;
begin
   ligne_w2:='';
   if eof(fic_w2) then lem_w2:='zz'
      else begin
           readln(fic_w2,ligne);
//           lem_w2:=trim(copy(ligne,1,pos(',',ligne)-1));
           lem_w2:=lowercase(trim(copy(ligne,1,pos(',',ligne)-1)));
           ligne_w2:=ligne;
      end;
end;

procedure lis_w3;
begin
   ligne_w3:='';
   if eof(fic_w3) then lem_w3:='zz'
      else begin
           readln(fic_w3,ligne);
//           lem_w3:=trim(copy(ligne,1,pos(',',ligne)-1));
           lem_w3:=lowercase(trim(copy(ligne,1,pos(',',ligne)-1)));
           ligne_w3:=ligne;
      end;
end;

procedure lis_w4;
begin
   ligne_w4:='';
   if eof(fic_w4) then lem_w4:='zz'
      else begin
           readln(fic_w4,ligne);
//           lem_w4:=trim(copy(ligne,1,pos(',',ligne)-1));
           lem_w4:=lowercase(trim(copy(ligne,1,pos(',',ligne)-1)));
           ligne_w4:=ligne;
      end;
end;

procedure ecris(var fichier:text);

begin
   writeln(fichier, lg_ls);
   writeln(fichier, lg_gj);
   writeln(fichier, lg_ge);
   writeln(fichier, lg_fg);
   writeln(fichier, lg_lw);
   writeln(fichier, lg_yo);
   writeln(fichier, lg_po);
   writeln(fichier, lg_wh);

end;

procedure relis(var fichier:text);

begin
   readln(fichier, lg_ls);
   readln(fichier, lg_gj);
   readln(fichier, lg_ge);
   readln(fichier, lg_fg);
   readln(fichier, lg_lw);
   readln(fichier, lg_yo);
   readln(fichier, lg_po);
   readln(fichier, lg_wh);

end;

procedure etape1;
var nn: integer;
    bis, bis_j: boolean;
{Cette première étape ouvre les 5 dictionnaires et les fichiers de morpho de
Whitaker. Elle compare les lemmes, supposés être tous rangés en ordre alphabétique.
Elle les sépare ensuite en trois groupes :
- Ceux qui ne figurent que dans un seul dictionnaire
- Ceux qui figurent dans au moins deux dictionnaires
- Ceux qui figurent plusieurs fois dans un dictionnaire.
Dans la première catégorie, se trouvent les formes non ramistes et semi-ramistes.}
begin
     assign(fic_lw,'input/lewis_orig.csv');
     reset(fic_lw);        {le petit Lewis}
     assign(fic_ls,'input/ls_fini.csv');
     reset(fic_ls);           {Le Lewis & Short}
     assign(fic_gj,'input/GJ6.csv');
     reset(fic_gj);           {Gérard Jeanneau}
     readln(fic_gj,ligne);
     assign(fic_ge,'input/Georges2.csv');
     reset(fic_ge);           {K.E. Georges 1913}
     assign(fic_fg,'input/extraits_fg2.csv');
     reset(fic_fg);           {abrégé du Gaffiot}
     assign(fic_yo,'input/lemmata.csv');
     reset(fic_yo);           {Lexique de Collatinus, sans traduction}
     assign(fic_po,'input/polheads.csv');
     reset(fic_po);           {Polheads, sans traduction}
     assign(fic_w1,'input/Whit_nom.csv');
     reset(fic_w1);        {Whitaker substantifs}
     assign(fic_w2,'input/Whit_adj.csv');
     reset(fic_w2);           {Whitaker adjectifs}
     assign(fic_w3,'input/Whit_parf.csv');
     reset(fic_w3);           {Whitaker parfaits}
     assign(fic_w4,'input/Whit_sup.csv');
     reset(fic_w4);           {Whitaker supins}

     assign(fic_out,'output/lem_ok1.csv');
     rewrite(fic_out);
     assign(rejet,'output/lem_isol1.csv');
     rewrite(rejet);
     assign(mots,'output/lem_mult1.csv');
     rewrite(mots);
//     assign(fic_in,'output/lem_SR1.csv');
//     rewrite(fic_in);
     nb_mots:=0;
     i:=0;
     lis_ls;
     lis_lw;
     lis_gj;
     lis_ge;
     lis_fg;
     lis_yo;
     lis_po;
     lis_w1;
     lis_w2;
     lis_w3;
     lis_w4;
     lem_prec:='zz';
     bis:=false;
     repeat
           lem_cour:=lem_ls;  // Un au hasard
           if (lem_fg<lem_cour) then lem_cour:=lem_fg;
           if (lem_ge<lem_cour) then lem_cour:=lem_ge;
           if (lem_lw<lem_cour) then lem_cour:=lem_lw;
           if (lem_yo<lem_cour) then lem_cour:=lem_yo;
           if (lem_po<lem_cour) then lem_cour:=lem_po;
           if (lem_gj<lem_cour) then lem_cour:=lem_gj;
           {lem_cour est le plus petit des lemmes}
           if ((lem_cour=lem_prec)) then begin
                {J'ai un lemme multiple à ranger dans le fichier mots}
                if not bis then writeln(mots,'|', lem_prec);
                   bis:=true;
                   ecris(mots)
              end
           else if bis then begin
                       // lemmes différents, mais le préc était multiple
                            ecris(mots);
                            bis:=false; // fin de la multiplicité.
                            end
           else begin
                {Le lemme précédent était unique
                à ranger dans le fichier fic_out ou rejet}
                bis:=false;
                if (n>1) then begin  {fic_out}
                       writeln(fic_out,'|', lem_prec);
                       ecris(fic_out);
                      end
                   else if (lem_prec<>'zz') then begin      {rejet}
                        writeln(rejet,'|', lem_prec);
                        ecris(rejet);
                       end
           end ;
           n:=0;
           if (lem_ls=lem_cour) then begin
                              n:=n+1;
                              lg_ls:='LS|'+ligne_ls;
                              lis_ls;
                              end
                              else lg_ls:='LS|';
           if (lem_gj=lem_cour) then begin
                              n:=n+1;
                              lg_gj:='GJ|'+ligne_gj;
                              lis_gj;
                              end
                              else lg_gj:='GJ|';
           if (lem_fg=lem_cour) then begin
                              n:=n+1;
                              lg_fg:='FG|'+ligne_fg;
                              lis_fg;
                              end
                              else lg_fg:='FG|';
           if (lem_yo=lem_cour) then begin
                              n:=n+1;  {YO est devenu ramiste ! }
                              lg_yo:='YO|'+ligne_yo;
                              lis_yo;
                              end
                              else lg_yo:='YO|';
           { Le petit Lewis et le Georges sont semi-ramistes et
           je voudrais éviter que des formes présentes seulement dans ces deux-là
           (avec un i qui devrait être j) soient rangées dans fic_out}
           if (lem_lw=lem_cour) then begin
                              if n>0 then n:=n+1;
                              // Je ne le compte que s'il a déjà été trouvé
                              lg_lw:='Lw|'+ligne_lw;
                              lis_lw;
                              end
                              else lg_lw:='Lw|';
           if (lem_ge=lem_cour) then begin
                              if n>0 then n:=n+1;
                              lg_ge:='Ge|'+ligne_ge;
                              lis_ge;
                              end
                              else lg_ge:='Ge|';
           // Les deux dernières sources d'information, polheads et Whitaker,
           // ne sont pas comptées comme des dicos (pas de tradustion, ramisme hésitant)
           if (lem_po=lem_cour) then begin
                              lg_po:='PO|'+ligne_po;
                              lis_po;
                              end
                              else lg_po:='PO|';
           if (lem_cour=lem_w1) then begin
                              lg_wh:='WW|'+ligne_w1;
                              lis_w1;
                              end
                else lg_wh:='WW|';
           while (lem_cour>lem_w2) do lis_w2;
           if (lem_cour=lem_w2) then begin
                              lg_wh:=lg_wh+'|'+ligne_w2;
                              lis_w2;
                              end
                else lg_wh:=lg_wh+'|';
           while (lem_cour>lem_w3) do lis_w3;
           if (lem_cour=lem_w3) then begin
                              lg_wh:=lg_wh+'|'+ligne_w3;
                              lis_w3;
                              end
                else lg_wh:=lg_wh+'|';
           while (lem_cour>lem_w4) do lis_w4;
           if (lem_cour=lem_w4) then begin
                              lg_wh:=lg_wh+'|'+ligne_w4;
                              lis_w4;
                              end
                else lg_wh:=lg_wh+'|';
           {J'ai compté le nombre de lemmes égaux, préparé les lignes de sortie
                et chargé le lemme suivant dans chaque dico.}
           lem_prec:=lem_cour;
           i:=i+1
   until ((lem_gj='zz') and (lem_ls='zz'));
//     until (eof(fic_gj) and eof(fic_ls));
//     until ((i>10000) or eof(fic_ls));
// Il faut encore sortir les dernières lignes ? OUI !
   writeln(fic_out,'|', lem_prec);
   ecris(fic_out);

   CloseFile(fic_ls);
     CloseFile(fic_lw);
     CloseFile(fic_gj);
     CloseFile(fic_ge);
     CloseFile(fic_fg);
     CloseFile(fic_w1);
     CloseFile(fic_w2);
     CloseFile(fic_w3);
     CloseFile(fic_w4);
     CloseFile(fic_out);
     CloseFile(rejet);
     CloseFile(mots);
//     CloseFile(fic_in);
end;

procedure range_w1;

var OK, OK1, OK2: boolean;
    {Je dois vérifier que c'est bien un lemme du petit Lewis ou du Georges que je récupère.}
begin
   {Aux j près, les lemmes dans fic_w1 et dans fic_w2 sont les mêmes.
   Je m'attends donc à trouver à trouver une info intéressante dans
   le petit Lewis (ligne Lw) et éventuellement dans lemmata.fr (ligne YO).
   Les autres lignes de fic_w1 sont à reproduire telles quelles dans fic_out.}

   relis(fic_w2);
   readln(fic_w2,ligne_w2);
   OK:=(lg_ls='LS|') and (lg_gj='GJ|') and (lg_fg='FG|') and (lg_yo='YO|');
   if OK then begin
      // On a probablement une vraie entrée semi-ramiste qui coïncide avec une autre ramiste
      nb_mots:=nb_mots+1;
      lgn[nb_mots]:=lem_w1;
      {C'est le lemme !
      Je dois repérer les mots que je récupère, pour les supprimer ensuite}
      writeln(fic_out,ligne_w1);  //  lemme
      readln(fic_w1,ligne_w1);
      writeln(fic_out,ligne_w1);  // LS
      readln(fic_w1,ligne_w1);
      writeln(fic_out,ligne_w1);  // GJ
      readln(fic_w1,ligne_w1);
      writeln(fic_out,lg_ge);  // GE : pas ramiste, donc ligne_w1 vide
      readln(fic_w1,ligne_w1);
      writeln(fic_out,ligne_w1);  // FG
      readln(fic_w1,ligne_w1);
      writeln(fic_out,lg_lw);  // Lw : pas ramiste, donc ligne_w1 vide
      readln(fic_w1,ligne_w1);
      if ligne_w1='PO|' then writeln(fic_out,lg_po)  // PO a des ratés.
                        else writeln(fic_out,ligne_w1);
      readln(fic_w1,ligne_w1);
      if ligne_w1='WW||||' then writeln(fic_out,lg_wh)  // WW ?
                           else writeln(fic_out,ligne_w1);
      readln(fic_w1,ligne_w1);
      end;
      repeat
           writeln(fic_out,ligne_w1);
           readln(fic_w1,ligne_w1);
      until (pos('|',ligne_w1)=1) or eof(fic_w1);

end;

procedure etape2a;
var ii:integer;

begin
     readln(fic_w1,ligne_w1); {C'est un lemme ramiste}
     readln(fic_w2,ligne_w2); {C'est un lemme éventuellement non-ramiste}
     repeat
           if (pos('j',ligne_w1)=0) then begin
                {Sans j, le lemme est bon : je le ré-écris}
                repeat
                      writeln(fic_out,ligne_w1);
                      readln(fic_w1,ligne_w1);
                until ((pos('|',ligne_w1)=1) or eof(fic_w1));
                      {les lemmes ont un | en première place}
                end
                else begin
                     lem_w1:=ligne_w1;
                     while (pos('j',lem_w1)<>0) do lem_w1[pos('j',lem_w1)]:='i';
                     {Je remplace les j par des i}
                     while (ligne_w2<lem_w1) do begin
                          repeat
                         //       writeln(rejet,ligne_w2);
                                readln(fic_w2,ligne_w2);
                          until ((pos('|',ligne_w2)=1) or eof(fic_w2));
                          end;
                     if (ligne_w2=lem_w1) then range_w1
                        else begin
                             repeat {non-trouvé !}
                                    writeln(fic_out,ligne_w1);
                                    readln(fic_w1,ligne_w1);
                             until ((pos('|',ligne_w1)=1) or eof(fic_w1));
                             CloseFile(fic_w2);
                             reset(fic_w2);
                             readln(fic_w2,ligne_w2);
                             end;
                     end;
     until (eof(fic_w1) or eof(fic_w2));
     {Je suis arrivé à la fin d'un des deux fichiers}
     if not(eof(fic_w1)) then repeat
                                writeln(fic_out,ligne_w1);
                                readln(fic_w1,ligne_w1);
                         until eof(fic_w1);
     writeln(fic_out,ligne_w1);
     CloseFile(fic_w1);
     CloseFile(fic_w2);
     CloseFile(fic_out);
{Je dois maintenant supprimer les mots récupérés}
end;

procedure supprime;

var OK:boolean;
    i:integer;

begin
   readln(fic_w2,ligne_w2);
   repeat
         OK:=true;
         for i:=0 to nb_mots do OK:=OK and (ligne_w2<>lgn[i]);
         if OK then repeat
               writeln(fic_out,ligne_w2);
               readln(fic_w2,ligne_w2);
               until ((pos('|',ligne_w2)=1) or eof(fic_w2))
               else repeat
                          readln(fic_w2,ligne_w2);
                    until ((pos('|',ligne_w2)=1) or eof(fic_w2))
   until eof(fic_w2);
   writeln(fic_out,ligne_w2);
   CloseFile(fic_w2);
   CloseFile(fic_out);
end;

procedure etape2;

begin
   assign(fic_w1,'output/lem_ok1.csv');
   reset(fic_w1);
   assign(fic_w2,'output/lem_isol1.csv');
   reset(fic_w2);
   assign(fic_out,'output/lem_ok2a.csv');
   rewrite(fic_out);
   nb_mots:=-1;
   etape2a;

   reset(fic_w2);
   assign(fic_w1,'output/lem_mult1.csv');
   reset(fic_w1);
   assign(fic_out,'output/lem_mult2a.csv');
   rewrite(fic_out);
   etape2a;

   reset(fic_w2);
   assign(fic_w1,'output/lem_isol1.csv');
   reset(fic_w1);
   assign(fic_out,'output/lem_isol2a.csv');
   rewrite(fic_out);
   etape2a;

   assign(fic_out,'output/lem_trouves.csv');
   rewrite(fic_out);
   for i:=0 to nb_mots do writeln(fic_out,lgn[i]);
   closefile(fic_out);
   assign(fic_w2,'output/lem_isol2a.csv');
   reset(fic_w2);
   assign(fic_out,'output/lem_isol2b.csv');
   rewrite(fic_out);
   supprime;
   // J'en ai fini avec les lemmes simples.
   // Il me reste 38 lemmes multiples issus des dicos semi-ramistes.
   // Finalement (le 16 décembre) j'ai décidé de tricher :
   // J'ai modifié en amont les entrées multiples avec j.
   // Le tri spécial vers lem_SR1.csv est donc devenu inutile.

{   nb_mots:=-1;
   assign(fic_w1,'output/lem_mult2a.csv');
   reset(fic_w1);
   assign(fic_w2,'output/lem_SR1.csv');
   reset(fic_w2);
   assign(fic_out,'output/lem_mult2b.csv');
   rewrite(fic_out);
   etape2a;
   // Je dois refaire la même chose, mais avec des lemmes multiples
   assign(fic_out,'output/lem_trouves2.csv');
   rewrite(fic_out);
   for i:=0 to nb_mots do writeln(fic_out,lgn[i]);
   closefile(fic_out);
   assign(fic_w2,'output/lem_SR1.csv');
   reset(fic_w2);
   assign(fic_out,'output/lem_SR2.csv');
   rewrite(fic_out);
   supprime;       }
end;

procedure liste_lem(pref : string);

begin
   readln(fic_in, ligne);
   repeat
         write(fic_out,pref,ligne);
         while pos('j',ligne)>0 do ligne[pos('j',ligne)]:='i';
         writeln(fic_out,ligne);
         repeat
               readln(fic_in, ligne);
         until ((pos('|',ligne)=1) or eof(fic_in));
   until eof(fic_in);
   CloseFile(fic_in);
end;

procedure liste_lemmes;

begin
   assign(fic_in,'output/lem_OK2a.csv');
   reset(fic_in);
   assign(fic_out,'output/list_lem.csv');
   rewrite(fic_out);
   liste_lem('OK');
   assign(fic_in,'output/lem_isol2b.csv');
   reset(fic_in);
   liste_lem('Isol');
   assign(fic_in,'output/lem_mult2a.csv');
   reset(fic_in);
   liste_lem('Mult');
   CloseFile(fic_out);
end;

initialization

     etape1;
              {Sépare les lemmes en 3 catégories :
              - les lemmes isolés (qui ne sont que dans un seul dico)
              - les lemmes simples (qui sont dans au moins 2 dicos)
              - les lemmes multiples (quel que soit le nb de dicos)
              Un traitement spécial est réservé aux 2 dicos Semi-Ramistes}
     etape2;
              {Cherche les j devenus i, dans petit Lewis et le Georges.
              Ces mots sont dans lem_isol1.csv quand ils sont simples et
              dans lem_SR1.csv quand ils sont multiples et Semi_Ramistes.
              Il faut les remettre au bon endroit dans lem_ok ou lem_mult.
              Les fichiers en sortie sont lem_ok2a.csv, lem_mult2a.csv et lem_isol2b.csv}
     liste_lemmes;
              {Je fais la liste des seuls lemmes trouvés dans les trois fichiers.}
end.

