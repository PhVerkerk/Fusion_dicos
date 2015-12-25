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
  tableau=array[0..15] of string;
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
  fic_ls,fic_gg,fic_lw,fic_gj,fic_ge,fic_fg,fic_yo,fic_po,fic_w1,fic_w2,fic_w3,fic_w4:text;
  ligne_ls,ligne_gg,ligne_lw,ligne_gj,ligne_ge,ligne_fg,ligne_yo,ligne_po,ligne_w1,ligne_w2,ligne_w3,ligne_w4:string;
  lem_ls,lem_gg,lem_lw,lem_gj,lem_fg,lem_ge,lem_yo,lem_po,lem_w1,lem_w2,lem_w3,lem_w4:string;
  lg_ls,lg_gg,lg_lw,lg_gj,lg_ge,lg_fg,lg_yo,lg_po,lg_wh:string;
  lem_prec, lem_cour: string;
  ligne, reste, mdl : string;
  i, n, nb_mots, numero : integer;
  lgn:array[0..9] of string;
  intrans, trans: boolean;
  // Beaucoup trop de variables globales, mais c'est pratique pour ne pas avoir
  // trop de paramètres à passer.

implementation

{$R *.lfm}

function car_utf_8(str:string;var i:integer):string;
// retourne le caractère utf-8 qui commence à l'octet i de str
var str2 : string;
    car : integer;

begin
   str2:='';
   if ((i>0)and(i<=length(str))) then begin
      repeat
         car:=ord(str[i]);
         i+=1;
      until ((car>64)or(i>length(str))); // j'ignore tout caractère <65.
      i-=1;
      if car<128 then str2:=str[i]
         else if car<192 then str2:=str[i] // ce cas ne devrait pas se produire
              else if car<224 then str2:=copy(str,i,2)
              else if car<240 then str2:=copy(str,i,3)
              else if car<248 then str2:=copy(str,i,4)
   end;
   if ((i+length(str2)+1<length(str))and(comb_breve=copy(str,i+length(str2),2))) then str2+=comb_breve;
   car_utf_8:=str2;
end;

function nettoie_gj(str:string):string;
   {Je dois supprimer les macr et brev qui sont en utf-8,
   et ne garder que le caractère sans longueur.}
var car:string;
    str1:string;
    ii,num:integer;

begin
     str1:='';
     ii:=1;
     while (pos(comb_breve,str)>0) do
           str:=copy(str,1,pos(comb_breve,str)-1)+copy(str,pos(comb_breve,str)+2,length(str));
     while (ii<=length(str)) do begin
        if (ord(str[ii])>=224) then begin
           if copy(str,ii,3)='ụ' then begin
              str1+='u';
              ii+=2;
              end
           end
           else if (ord(str[ii])>=192) then begin
                num:=(ord(str[ii])-192)*256+ord(str[ii+1]);
                case num of
                     900, 1152, 1154 : car:='A';
                     932, 1153, 1155 : car:='a';
                     896, 907, 1170, 1172 : car:='E';
                     937, 939, 1171, 1173 : car:='e';
                     911, 1194, 1196 : car:='I';
                     943, 1195, 1197 : car:='i';
                     918, 1420, 1422 : car:='O';
                     950, 1421, 1423 : car:='o';
                     924, 1450, 1452 : car:='U';
                     956, 1451, 1453 : car:='u';
                     2226, 4238 : car:='Y';
                     2227, 4510 : car:='y';
                end;
                ii:=ii+1;
                str1:=str1+car;
              end
           else str1:=str1+str[ii];
           ii:=ii+1;
   end;
   nettoie_gj:=str1;
end;

function coupe(str:string):string;

begin
   while pos(' - ',str)>0 do
      str:=copy(str,1,pos('-',str)-2)+copy(str,pos('-',str)+2,length(str));
   if pos(',',str)>0 then str:=copy(str,1,pos(',',str)-1);
   if pos('.',str)>0 then str:=copy(str,1,pos('.',str)-1);
   if pos(' ',str)>0 then str:=copy(str,1,pos(' ',str)-1);
   if pos('=',str)>0 then str:=copy(str,1,pos('=',str)-1);
   while pos('-',str)>0 do
      str:=copy(str,1,pos('-',str)-1)+copy(str,pos('-',str)+1,length(str));
   if ((pos('(',str)>1)and(pos(')',str)>1)) then
      str:=copy(str,1,pos('(',str)-1)+copy(str,pos(')',str)+1,length(str))
   else begin
        if pos('(',str)>0 then
           str:=copy(str,1,pos('(',str)-1)+copy(str,pos('(',str)+1,length(str));
        if pos(')',str)>0 then
           str:=copy(str,1,pos(')',str)-1)+copy(str,pos(')',str)+1,length(str));
   end;
   while ((length(str)>1) and (ord(str[length(str)])<64)) do
      str:=copy(str,1,length(str)-1);
   coupe:=str;
end;

function nettoie(str:string):string;
   {Je dois supprimer les macr et brev qui sont en utf-8,
   et ne garder que le caractère sans longueur.}
var car:string;
    str1:string;

begin
     nettoie:=nettoie_gj(coupe(str));
end;

function ote_breves(str:string):string;
   {Je dois supprimer les brev qui sont en utf-8,
   et ne garder que le caractère sans longueur.}
var car:string;
    str1:string;
    ii,num:integer;

begin
     str1:='';
     ii:=1;
     while (pos(comb_breve,str)>0) do
           str:=copy(str,1,pos(comb_breve,str)-1)+copy(str,pos(comb_breve,str)+2,length(str));
     while (ii<=length(str)) do begin
       if (ord(str[ii])>=192) then begin
                num:=(ord(str[ii])-192)*256+ord(str[ii+1]);
                case num of
                     900, 1154 : car:='A';
                     932, 1155 : car:='a';
                     896, 907, 1172 : car:='E';
                     937, 939, 1173 : car:='e';
                     911, 1196 : car:='I';
                     943, 1197 : car:='i';
                     918, 1422 : car:='O';
                     950, 1423 : car:='o';
                     924, 1452 : car:='U';
                     956, 1453 : car:='u';
                     4238 : car:='Y';
                     4510 : car:='y';
                end;
                ii:=ii+1;
                str1:=str1+car;
              end
           else str1:=str1+str[ii];
           ii:=ii+1;
   end;
   ote_breves:=str1;
end;

function compatible(mot1,mot2:string;var mot3:string):boolean;

var OK : boolean;
    i1, i2, l1, l2 : integer;
    car1, car2 : string;

begin
   OK:=true;
   i1:=1;
   i2:=1;
   l1:=length(mot1);
   l2:=length(mot2);
   mot3:='';
   if mot1='' then mot3:=mot2
   else if mot2='' then mot3:=mot1
   else if nettoie_gj(mot1)<>nettoie_gj(mot2) then begin
        OK:=false;
        {if length(nettoie_gj(mot1))<length(nettoie_gj(mot2)) then mot3:=mot2
                                                             else} mot3:=mot1;
      end
   else
   repeat
      car1:=car_utf_8(mot1,i1);
      car2:=car_utf_8(mot2,i2);
      if car1=car2 then mot3+=car1
      else if length(car1)>1 then begin
         if length(car2)=1 then mot3+=car1
            else if pos(comb_breve,car1)>0 then mot3+=car1
            else if pos(comb_breve,car2)>0 then mot3+=car2
            else begin mot3+=car1; OK:=false end;
      end
      else begin
         if length(car2)>1 then mot3+=car2
            else begin // cas un peu pathologique,
                       // dû à une majuscule intempestive
                       // ou à une assimilation.
                 mot3+=car1;
                 // OK:=false // je passe outre ?
            end;
      end;
      i1+=length(car1);
      i2+=length(car2);
   until ((i1>l1)or(i2>l2));
   compatible:=OK;
end;

procedure explose(str,sep:string; var tab:tableau);

var i:integer;

begin
   for i:=0 to 15 do tab[i]:='';
   i:=0;
   while ((pos(sep,str)>0)and(i<15)) do begin
         tab[i]:=copy(str,1,pos(sep,str)-1);
         i+=1;
         str:=copy(str,pos(sep,str)+1,length(str));
         end;
   tab[i]:=str; // Le dernier champ.
end;


function voyelle(car:char):boolean;

begin
     car:=chr(ord(car) and 223);
     voyelle:=(car='A') or (car='E') or (car='I') or (car='O') or (car='U') or(car='Y')
end;

function consonne(car:char):boolean;

var asc:integer;

begin
     asc:=ord(car) and 223;   // 255 - 32 : met en majuscule les ascii <128
     consonne:=(asc>64) and (asc<91) and (not voyelle(chr(asc))) and (asc<>72)
     // Le "h" n'est pas une consonne qui compte pour les longues par position
end;

function recolle(f1,f2:string):string;

var str:string;
    i:integer;

begin
   if f2='' then str:=f1
   else if consonne(f2[1]) then begin
      if pos(f2[1],f1)>0 then begin
         i:=length(f1);
         while f1[i]<>f2[1] do i-=1;
         str:=copy(f1,1,i-1)+f2;
      end
      else str:=f1+'+'+f2;
   end
   else str:=f1+'+'+f2; // Si c'est une voyelle, je n'insiste pas...
   recolle:=str;
end;

function db_consonne(position:integer;chaine:string):boolean;

var db_c:boolean;

begin
     db_c:=false;
     if (position<length(chaine)) then begin
         db_c:=(consonne(chaine[position]) and consonne(chaine[position+1]));
         db_c:=db_c or (chaine[position]='x') or (chaine[position]='j');
         db_c:=db_c or (chaine[position]='z');
     end;
     db_consonne:=db_c;
end;

function longue(car:char):string;

var str:string;

begin
     str:='';
     case car of
          'A' : str:='Ā';
          'a' : str:='ā';
          'E' : str:='Ē';
          'e' : str:='ē';
          'I' : str:='Ī';
          'i' : str:='ī';
          'O' : str:='Ō';
          'o' : str:='ō';
          'U' : str:='Ū';
          'u' : str:='ū';
          'Y' : str:='Ȳ';
          'y' : str:='ȳ';
          else str:=car;
     end;
     longue:=str;
end;

function breve(car:char):string;

var str:string;

begin
     str:='';
     case car of
          'A' : str:='Ă';
          'a' : str:='ă';
          'E' : str:='Ĕ';
          'e' : str:='ĕ';
          'I' : str:='Ĭ';
          'i' : str:='ĭ';
          'O' : str:='Ŏ';
          'o' : str:='ŏ';
          'U' : str:='Ŭ';
          'u' : str:='ŭ';
          'Y' : str:='Ў';
          'y' : str:='ў';
     end;
     breve:=str;
end;

function u_muet(i:integer;chaine:string):boolean;

var um:boolean;
    toto:string;

begin
     um:=false;
     if ((chaine[i]='u') and (i>1)) then begin
             if ((chaine[i-1]='q') or (chaine[i-1]='Q')) then um:=true
                else if ((chaine[i-1]='g') or (chaine[i-1]='G')) then begin
                    toto:=nettoie_gj(copy(chaine,i+1,length(chaine)));
                    um:=('us'<>toto); // Les adjectifs en -guus
                    end
             else if ((chaine[i-1]='s') or (chaine[i-1]='S')) then begin
                    toto:=nettoie_gj(copy(chaine,i+1,length(chaine)));
                    um:=(toto='adeo')or(toto='avis')or(toto='esco');
                    // Les composés de suadeo, suavis et suesco
                    end;
     end;
     u_muet:=um;
end;

function muette_liquide(i:integer;chaine:string):boolean;

begin
     muette_liquide:=(pos(chaine[i],'bpgcdtf')>0)and(pos(chaine[i+1],'lr')>0);
end;

function rend_commune(chaine:string):string;

// function qui retourne la chaine en ayant rendu commune la voyelle en dernière
// position si elle est brève.

var str, car : string;
    i: integer;

begin
   i:=length(chaine);
   str:='';
   if i>0 then begin
   while ((i>0)and(ord(chaine[i])>127)and(ord(chaine[i])<196)) do i-=1;
   car:=copy(chaine,i,length(chaine));
   str:=copy(chaine,1,i-1);
   if voyelle(car[1]) then str+=longue(car[1])+comb_breve
      else if pos(car,'ă ĕ ĭ ŏ ŭ')>0 then str+=car[1]+chr(ord(car[2])-2)+comb_breve
           else if car='ў' then str+='ȳ'+comb_breve
                else str+=car;
   end;
   rend_commune:=str;
end;

function par_position(str:string;breve_par_defaut:boolean):string;

var str1, toto : string;
    i, n : integer;

begin
     str1:='';
     i:=1;
     n:=length(str);
     if n>0 then
     repeat
        if voyelle(str[i]) then begin
           // J'ai une voyelle sans quantité
            if consonne(str[i+1]) then begin
               // Elle est suivie d'une consonne
                if db_consonne(i+1,str) then begin
                   str1+=longue(str[i]);
                   if muette_liquide(i+1,str) then str1+=comb_breve;
                   end
                   else if str[i+1]='x' then str1+=longue(str[i]) // x final
                   else if breve_par_defaut then str1+=breve(str[i])
                                            else str1+=str[i];
            end
            else begin
            if str[i+1]='h' then begin
               // un h entre deux voyelles ne compte pas
               toto:=nettoie_gj(copy(str,i+2,n));
               if ((length(toto)>0)and(voyelle(toto[1]))) then str1+=breve(str[i])
                                                          else str1+=str[i];
               // La dernière voyelle reste souvent sans quantité.
               // Or cette quantité est importante pour les imparisyllabiques et les invariables
               // Se plonger dans Quicherat pour la dernière voyelle.
               // Ici ou seulement si c'est nécessaire ?
            end
            else
                 // Ma voyelle n'est pas suivie par une consonne
            if u_muet(i,str) then str1+='ụ' // mettre ici un 'u' ou un 'ụ'
                             else
                 if ord(str[i+1])>128 then str1+=breve(str[i])
                    else begin
                        // Est-ce une diphtongue ?
                        if pos(copy(str,i,2),'ae oe au eu Ae Oe Au Eu')=0 then
                                                 str1+=breve(str[i])
                           else begin
                              if ((i=3)and (copy(str,1,4)='prae')) then begin
                                 // le préfixe prae peut devenir bref devant un voyelle
                                 if (n<5) then str1:='prāe'
                                 else if voyelle(str[5]) then str1:='prăe'
                                    else str1:='prāe';
                                 i:=4
                                 end
                              else begin
                               str1+=longue(str[i])+str[i+1];
                               i+=1;
                              end;
                           end;
                    end;
            end;
        end
        else str1+=str[i];
        i+=1;
     until i>=n;
     if i=n then str1+=str[i]; // la dernière lettre.
     // Se plonger dans Quicherat pour les voyelles finales
     if voyelle(str1[length(str1)]) then begin
        if pos(copy(str,n-1,2),'ae oe au eu Ae Oe Au Eu')=0 then begin
           // J'ai une voyelle à la fin du mot et ce n'est pas une diphtongue
           end;
        end
        else if voyelle(str1[length(str1)-1]) then begin
           // J'ai une voyelle puis une consonne.
           if pos(str[n],'bdlmrt')>0 then str1:=copy(str1,1,length(str1)-2)+breve(str1[length(str1)-1])+str[n]
              else begin

              end;
        end;
     par_position:=str1;
end;

procedure test_pp;

var lemme, orth, orth2 : string;

begin
     assign(fic_yo,'input/lemmata.csv');
     reset(fic_yo);           {Lexique de Collatinus, sans traduction}
     assign(fic_out,'output/test_pp.csv');
     rewrite(fic_out);
     repeat
        readln(fic_yo,ligne);
        ligne:=copy(ligne,pos('|',ligne)+1,length(ligne));
        lemme:=copy(ligne,1,pos('|',ligne)-1);
        if pos('=',lemme)>0 then begin
            orth:=copy(lemme,pos('=',lemme)+1,length(lemme));
            lemme:=copy(lemme,1,pos('=',lemme)-1);
            if ord(lemme[length(lemme)])<64 then
               lemme:=copy(lemme,1,length(lemme)-1);
            orth2:=par_position(lemme,false);
            if orth<>orth2 then
               writeln(fic_out,orth2,'|',ligne);
        end;
     until eof(fic_yo);
     CloseFile(fic_yo);
     CloseFile(fic_out);
end;

function utf2ascii(str:string):string;
// Remplace les voyelles marquées en utf-8 par une notation ASCII :
// "voyelle" suivie de + (longue), - (brève) ou * (commune)
// Garde les majuscules !
// Est-ce que je sais écrire la routine inverse ?

var str1,car:string;
    num, ii: integer;

begin
   ii:=0;
   str1:='';
   car:='';
   if length(str)>0 then
   repeat
      ii:=ii+1;
      if ord(str[ii])>191 then
         begin
         num:=(ord(str[ii])-192)*256+ord(str[ii+1]);
         case num of
              1152 : car:='A+';
              1170 : car:='E+';
              1194 : car:='I+';
              1420 : car:='O+';
              1450 : car:='U+';
              2226 : car:='Y+';
              1154 : car:='A-';
              1172 : car:='E-';
              1196 : car:='I-';
              1422 : car:='O-';
              1452 : car:='U-';
              4237 : car:='Y-';
              1153 : car:='a+';
              1171 : car:='e+';
              1195 : car:='i+';
              1421 : car:='o+';
              1451 : car:='u+';
              2227 : car:='y+';
              1155 : car:='a-';
              1173 : car:='e-';
              1197 : car:='i-';
              1423 : car:='o-';
              1453 : car:='u-';
              4510 : car:='y-';
         end;
         ii:=ii+1;
         if copy(str,ii+1,2)=comb_breve then begin
                                      car[2]:='*';
                                      ii:=ii+2; end;
         str1:=str1+car;
         end
      else str1:=str1+str[ii];
   until ii>=length(str);
   utf2ascii:=str1;
end;

function vers_PedeCerto(str:string):string;
// Retourne une chaine avec les quantités des syllabes.
// Suppose que toutes les voyelles sont marquées, sauf la 2ème d'une diphtongue.
// Le format de sortie est celui du fichier Prosodie_PedeCerto :
// + (longue), - (brêve) ou * (commune)

var str1,car:string;
    num, ii: integer;

begin
   ii:=0;
   str1:='';
   car:='';
   if length(str)>0 then begin
   repeat
      ii:=ii+1;
      if ord(str[ii])>191 then
         begin
         num:=(ord(str[ii])-192)*256+ord(str[ii+1]);
         case num of
              1152, 1153 : car:='a+';
              1170, 1171 : car:='e+';
              1194, 1195 : car:='i+';
              1420, 1421 : car:='o+';
              1450, 1451 : car:='u+';
              2226, 2227 : car:='y+';
              1154, 1155 : car:='a-';
              1172, 1173 : car:='e-';
              1196, 1197 : car:='i-';
              1422, 1423 : car:='o-';
              1452, 1453 : car:='u-';
              4237, 4510 : car:='y-';
         end;
         ii:=ii+1;
         if copy(str,ii+1,2)=comb_breve then begin
                                      car[2]:='*';
                                      ii:=ii+2; end;
         str1:=str1+car;
         end
      else str1:=str1+str[ii];
   until ii>=length(str);
   ii:=length(str1);
   while (not voyelle(str1[ii])) do ii:=ii-1;
   // Je suis sur la dernière voyelle
   // Pour l'instant, je dois supprimer la dernière quantité (non-donnée par PedeCerto)
   // Dans l'avenir, je devrais garder la longueur de la dernière (et la déterminer si ce n'est pas fait)
   if ii<length(str1) then begin
      if ((str1[ii+1]='+')or(str1[ii+1]='-')or(str1[ii+1]='*')) then
           str1:=copy(str1,1,ii)+copy(str1,ii+2,length(str1))
           else if ({(str1[ii]='e')and}(str1[ii-1]='+')) then
                str1:=copy(str1,1,ii-2)+copy(str1,ii,length(str1))
                else str1:=str1+'?';
   end
   else if ((str1[ii]='e')and(str1[ii-1]='+')) then // c'est un ae
        str1:=copy(str1,1,ii-2)+copy(str1,ii,length(str1))
        else str1:=str1+'?';

   car:='';
   for ii:=1 to length(str1) do
        if ((str1[ii]='+')or(str1[ii]='-')or(str1[ii]='*')or(str1[ii]='?')) then
           car:=car+str1[ii];
   car:=car+'*';
   end;
   vers_PedeCerto:=car;
end;

function vers_PedeCerto2(str:string):string;
// Retourne une chaine avec les quantités des syllabes.
// Suppose que toutes les voyelles sont marquées, sauf la 2ème d'une diphtongue.
// Le format de sortie est celui du fichier Prosodie_PedeCerto :
// + (longue), - (brêve) ou * (commune)

var str1,car:string;
    num, ii: integer;

begin
   ii:=0;
   str1:='';
   car:='';
   if length(str)>0 then begin
   repeat
      ii:=ii+1;
      if ord(str[ii])>191 then
         begin
         num:=(ord(str[ii])-192)*256+ord(str[ii+1]);
         case num of
              1152, 1153 : car:='a+';
              1170, 1171 : car:='e+';
              1194, 1195 : car:='i+';
              1420, 1421 : car:='o+';
              1450, 1451 : car:='u+';
              2226, 2227 : car:='y+';
              1154, 1155 : car:='a-';
              1172, 1173 : car:='e-';
              1196, 1197 : car:='i-';
              1422, 1423 : car:='o-';
              1452, 1453 : car:='u-';
              4237, 4510 : car:='y-';
         end;
         ii:=ii+1;
         if copy(str,ii+1,2)=comb_breve then begin
                                      car[2]:='*';
                                      ii:=ii+2; end;
         str1:=str1+car;
         end
      else if consonne(str[ii]) then str1:=str1+str[ii]
      else begin
           // C'est une voyelle non-marquée.
           // Pour l'instant, je n'ai pas besoin de savoir si c'est une diphtongue.
           str1:=str1+str[ii]+'?';
      end;
   until ii>=length(str);
   // Il me reste à voir si des voyelles non-marquées sont définies par position
   for ii:=1 to length(str1)-1 do
        if str1[ii]='?' then begin
           if voyelle(str1[ii+1]) then str1[ii]:='-'
              else if ii<length(str1)-2 then
                 if consonne(str1[ii+2]) then str1[ii]:='+';
        end;
   ii:=length(str1);
   while ((ii>0) and (not voyelle(str1[ii]))) do ii-=1;
   // La quantité de la dernière voyelle est souvent indéterminée.
   str1[ii+1]:='*';
   end;
   vers_PedeCerto2:=str1;
end;

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
//                     reste:=copy(ligne,pos('|',ligne)+1,length(ligne));
//                     lem_ls:=trim(copy(reste,1,pos('|',reste)-1));
                     lem_ls:=lowercase(trim(copy(ligne,1,pos('|',ligne)-1)));
                     ligne_ls:=ligne;
                     end;
             end
end;

procedure lis_gg;
begin
   ligne_gg:='';
   if eof(fic_gg) then lem_gg:='zz'
        else begin
     repeat
     readln(fic_gg, ligne);
     until ((pos('|',ligne)<>0) or eof(fic_gg)) ;
     if (pos('|',ligne)=0) then lem_gg:='zz'
        else begin
             lem_gg:=lowercase(trim(copy(ligne,1,pos('|',ligne)-1)));
             if (pos(' ',lem_gg)<>0) then lem_gg:=copy(lem_gg,1,pos(' ',lem_gg)-1);
             ligne_gg:=ligne;
             end
        end;
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
//             reste:=copy(ligne,pos('|',ligne)+1,length(ligne));
             lem_lw:=lowercase(trim(copy(ligne,1,pos('|',ligne)-1)));
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
   writeln(fichier, lg_gg);
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
   readln(fichier, lg_gg);
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
     assign(fic_lw,'in_norm/lewis_orig_n.csv');
     reset(fic_lw);        {le petit Lewis}
     assign(fic_ls,'in_norm/ls_fini_n.csv');
     reset(fic_ls);           {Le Lewis & Short}
     assign(fic_gg,'in_norm/Gaffiot_GG_fini.csv');
     reset(fic_gg);           {Gaffiot de Gérard Gréco}
     assign(fic_gj,'input/GJ7.csv');
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
     lis_gg;
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
           if (lem_gg<lem_cour) then lem_cour:=lem_gg;
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
           if (lem_gg=lem_cour) then begin
                              n:=n+1;
                              lg_gg:='GG|'+ligne_gg;
                              lis_gg;
                              end
                              else lg_gg:='GG|';
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
     CloseFile(fic_gg);
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
   OK:=(lg_ls='LS|') and (lg_gg='GG|') and (lg_gj='GJ|') and (lg_fg='FG|') and (lg_yo='YO|');
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
      writeln(fic_out,ligne_w1);  // GG
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

var i,n,n1:integer;

begin
   readln(fic_in, ligne);
   repeat
         write(fic_out,pref,ligne);
//         while pos('j',ligne)>0 do ligne[pos('j',ligne)]:='i';
  //       writeln(fic_out,ligne);
           i:=0;
           n:=0;
           n1:=0;
         repeat
               readln(fic_in, ligne);
               i+=1;
               if ((pos('|',ligne)>1) and (length(ligne)>5) and (ligne<>'WW||||')) then
                  begin
                  if i<10 then n1+=1
                          else n+=1;
                  end;
         until ((pos('|',ligne)=1) or eof(fic_in));
         writeln(fic_out,'|',n1,'|',n,'|',i);
   until eof(fic_in);
   CloseFile(fic_in);
end;

procedure liste_lemmes;

begin
   assign(fic_out,'output/list_lem4db.csv');
   rewrite(fic_out);
{   assign(fic_in,'output/lem_OK2a.csv');
   reset(fic_in);
   liste_lem('OK');
   assign(fic_in,'output/lem_isol2b.csv');
   reset(fic_in);
   liste_lem('Isol');
   assign(fic_in,'input/lem_OK3m.csv');
   reset(fic_in);
   liste_lem('OKm');
   assign(fic_in,'output/lem_mult3c.csv');
   reset(fic_in);
   liste_lem('M3');    }
   assign(fic_in,'input/lem_Extra4db4.csv');
   reset(fic_in);
   liste_lem('E4');
   assign(fic_in,'input/lem_Extra4db8.csv');
   reset(fic_in);
   liste_lem('E8');
   CloseFile(fic_out);
end;

procedure liste_lem2(pref : string);

var i,n,n1:integer;
    nn: array [1..9] of integer;
    str : string;

begin
   repeat
      readln(fic_in, ligne);
      str:='';
      if pos('=',ligne)>0 then write(fic_out,pref,copy(ligne,1,pos('=',ligne)-1))
         else write(fic_out,pref,ligne);
         for i:=1 to 9 do begin
              nn[i]:=0;
             if not eof(fic_in) then readln(fic_in, ligne);
             if ((length(ligne)>5) and (ligne<>'WW||||')) then
                  begin
                  str+='X';
                  nn[i]:=1;
                  end
             else str+='-';
         end;
         n1:=nn[1]+nn[2];      // Les grands dicos
         n:=nn[3]+nn[4]+nn[6]+nn[7]+nn[8]; // dicos avec quantités
         i:=nn[5]+nn[9];  // dicos sans quantités
         write(fic_out,'|',n1+n+i,'|',n1,'|',n,'|',i);
         write(fic_out,'|',n1+nn[3]+nn[4]+nn[6]+nn[7]+nn[5]); // avec traduction
         for i:=1 to 9 do write(fic_out,'|',nn[i]);
         writeln(fic_out,'|',str);
   until eof(fic_in);
   CloseFile(fic_in);
end;

procedure liste_lemmes2;

begin
   assign(fic_out,'output/list_lem6.csv');
   rewrite(fic_out);
   assign(fic_in,'output/lem_Extra6.txt');
   reset(fic_in);
   liste_lem2('E6');
   assign(fic_in,'input/lem_Coll5.csv');
   reset(fic_in);
   liste_lem2('C5');
   CloseFile(fic_out);
end;

procedure adj_sub(pref : string);

var i,n,n1:integer;
    nn: array [1..9] of integer;
    lgn : array[0..9] of string;
    str : string;
    OK : boolean;

begin
   repeat
      for i:=0 to 9 do readln(fic_in, lgn[i]);
      lgn[0]+='2';
      OK:=(pos('subst.',lowercase(lgn[1]))>0) or (pos('subst.',lowercase(lgn[2]))>0);
      OK:=OK or (pos('pris subst',lowercase(lgn[2]))>0);
      OK:=OK or (pos('subst.',lowercase(lgn[3]))>0);
      if OK then
         for i:=0 to 9 do writeln(fic_out, lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
end;

procedure adj_subst;

begin
   assign(fic_out,'output/lem_AdjSub5.txt');
   rewrite(fic_out);
   assign(fic_in,'input/lem_Extra5.csv');
   reset(fic_in);
   adj_sub('E5');
   assign(fic_in,'input/lem_Coll5.csv');
   reset(fic_in);
   adj_sub('C5');
   CloseFile(fic_out);
end;

procedure Separe_Coll;

var    eclats : tableau;

begin
   repeat
   for i:=0 to 9 do begin
        readln(fic_in,ligne);
        lgn[i]:=ligne;
{        if ((i>0) and (i<8) and (length(ligne)>7)) then begin
           explose(ligne,'|',eclats);
           if lowercase(eclats[1])<>lowercase(nettoie(eclats[2])) then lgn[0]+='£'+chr(48+i);
        end;  }
   end;
   if length(lgn[7])>5 then begin
        for i:=0 to 9 do writeln(fic_out,lgn[i]);
   end
   else begin
   for i:=0 to 9 do writeln(mots,lgn[i]);
   end;
   until eof(fic_in);
   CloseFile(fic_in);
end;
procedure Separe_Collatinus;

begin
   assign(fic_in,'output/lem_OK2a.csv');
   reset(fic_in);
   assign(fic_out,'output/lem_Coll4.csv');
   rewrite(fic_out);
   assign(mots,'output/lem_Extra4.csv');
   rewrite(mots);
   Separe_Coll;
   assign(fic_in,'output/lem_isol2b.csv');
   reset(fic_in);
   Separe_Coll;
   assign(fic_in,'input/lem_OK3m.csv');
   reset(fic_in);
   Separe_Coll;
   assign(fic_in,'output/lem_mult3c.csv');
   reset(fic_in);
   Separe_Coll;
   CloseFile(fic_out);
   CloseFile(mots);
end;

function LS_pilote(i:integer):boolean;

begin
   LS_pilote:=true;
end;

procedure sortie(var fichier:text;nn:integer);

var i:integer;

begin
   writeln(fichier,'|',lem_cour);
   for i:=0 to nn do begin
        if (((i mod 9)=0)and(i>0)) then
           writeln(fichier,'|',lem_cour,(i div 9) + 1);
        writeln(fichier,lgn[i]);
   end;

end;

function range(pilot,nn:integer):boolean;
// Cette fonction range les lemmes multiples qui sont contenus dans le tableau lgn.
// Le pilote est le L&S ou le Gaffiot pour lequel la désinence est en 3e col.,
// le genre en 4e et le pos en 5e.
// Si ces informations permettent d'ordonner toutes les lignes (de 0 à nn),
// la fonction retourne true. Sinon, false.
var OK : boolean;
    str, str1, info : string;
    eclats : tableau;
    nvl_lgn : array[0..63] of string;
    echange : array[0..63] of integer;
    i,j,k,l,j_max, max:integer;
    nvl_place, recouvr: array[0..7] of integer;
    orth, orth2, desin, genre, p_o_s : array[0..7] of string;

begin
   OK:=true; // Je suis optimiste.
   j_max:=nn div 9;
   for i:=0 to nn do echange[i]:=i;
   // A priori, chaque ligne reste à sa place.
   // Je vais regarder chaque éléments et le rapprocher du bon pilote
   for j:=0 to j_max do begin
       explose(lgn[j*9+pilot],'|',eclats);
       // j'examine chaque ligne du pilote.
       // Les éclats sont numérotés à partir de 0, mais en 0, c'est le nom du dico
       orth[j]:=eclats[2]; // la forme avec quantités.
       orth2[j]:=ote_breves(eclats[2]); // la forme avec les longues pour le Ge et le Lw.
       desin[j]:=lowercase(nettoie_gj(eclats[3]));
       genre[j]:=eclats[4];
       p_o_s[j]:=eclats[5];
       if ((pilot=0) and (copy(eclats[5],1,2)='v.')) then p_o_s[j]:='verbe';
       if ((pilot=1) and (pos('tr.',eclats[5])>0)) then p_o_s[j]:='verbe';
   end;
   for i:=0 to 8 do if (i<>pilot) then begin
       // Le pilote reste à sa place
       // Je dois traiter de façon cohérente l'ensemble des lignes du dico i.
       // Si la ligne j1 correspond à l'entrée j2, je dois recaser la ligne j2
       for j:=0 to j_max do nvl_place[j]:=-1;
       // nvl_place contiendra le numéro de la ligne du pilote qui offre
       // un recouvrement maximal. -1 est la valeur initiale (sans préférence).
       j:=0;
       while ((j<=j_max) and (length(lgn[j*9+i])>7)) do begin
           // La ligne n'est pas vide. À quelle entrée se rapporte-t-elle ?
           explose(lgn[j*9+i],'|',eclats);
           case i of
                0, 1, 5 : begin    // LS, GG et Lw
           // Pour i=0, 1 ou 5, les champs sont identiques.
                    for k:=0 to j_max do begin
                        recouvr[k]:=0;
                        // Le recouvrement entre la ligne courante et la k-ième du pilote.
                        // if lowercase(nettoie_gj(eclats[3]))=desin[k] then recouvr[k]+=1;
                        if eclats[2]=orth[k] then recouvr[k]+=1
                        else if ((eclats[2]=orth2[k])and(i=5))
                                             then recouvr[k]+=1;
                        if eclats[4]=genre[k] then recouvr[k]+=1
                        else if ((eclats[4]=copy(genre[k],1,1))and(i=5))
                                             then recouvr[k]+=1;
                        if eclats[5]=p_o_s[k] then recouvr[k]+=1;
                        if p_o_s[k]='verbe' then begin
                           if ((i=0)and(copy(eclats[5],1,2)='v.')) then recouvr[k]+=1;
                           if ((i=1)and(pos('tr.',eclats[5])>0)) then recouvr[k]+=1;
                        end;
                        // L'égalité est une condition trop forte : prep. = prep. avec abl.
                        info:=lowercase(nettoie_gj(eclats[3]));
                        if length(info)>length(desin[k]) then begin
                        if pos(desin[k],info)>0 then recouvr[k]+=1;
                        end
                        else if pos(info,desin[k])>0 then recouvr[k]+=1;
                        end;
                    end;
                2, 3 : begin       // GJ et Ge
                    if eclats[2]=orth[k] then recouvr[k]+=1
                    else if ((eclats[2]=orth2[k])and(i=3))
                                         then recouvr[k]+=1;
                    info:=lowercase(nettoie_gj(eclats[3]));
           // Pour 2 et 3, toute l'info est dans le champ 3.
                    for k:=0 to j_max do begin
                        recouvr[k]:=0;
                        if desin[k]<>'' then if pos(desin[k],info)>0 then recouvr[k]+=1;
                        if genre[k]<>'' then if pos(genre[k],info)>0 then recouvr[k]+=1;
                        if p_o_s[k]<>'' then if pos(p_o_s[k],info)>0 then recouvr[k]+=1;
                        if p_o_s[k]='verbe' then
                           // c'est un verbe.
                           if pos('tr.',eclats[4])>0 then recouvr[k]+=1;
                        // En réalité, il faudrait décomposer les formes canoniques
                        // et comparer élément par élément.
                        end;
                    end;
                4: begin           // FG
                   info:=lowercase(nettoie_gj(eclats[2]));
                   // Pour 4, dans 2. Couper le premier mot.
                   info:=copy(info,pos(' ',info)+1,length(info));
                   for k:=0 to j_max do begin
                       recouvr[k]:=0;
                       if desin[k]<>'' then begin
                          if pos(desin[k],info)>0 then recouvr[k]+=1;
                          if ((desin[k]='a, um')and(pos('a um,',info)=1)) then recouvr[k]+=1;
                       end;
                       if genre[k]<>'' then begin
                       if ((genre[k]='f.') and (pos('feminin',info)>0)) then recouvr[k]+=1;
                       if ((genre[k]='m.') and (pos('masculin',info)>0)) then recouvr[k]+=1;
                       if ((genre[k]='n.') and (pos('neutre',info)>0)) then recouvr[k]+=1;
                       end;
                       if p_o_s[k]<>'' then if pos(p_o_s[k],info)>0 then recouvr[k]+=1;
                       if ((p_o_s[k]='adv.') and (pos('adverbe',info)>0)) then recouvr[k]+=1;
                       if ((p_o_s[k]='prep.') and (pos('preposition',info)>0)) then recouvr[k]+=1;
                       if ((p_o_s[k]='interj.') and (pos('interjection',info)>0)) then recouvr[k]+=1;
                       if ((p_o_s[k]='indecl.') and (pos('indeclinable',info)>0)) then recouvr[k]+=1;
                       if ((p_o_s[k]='verbe') and (pos('transitif',info)>0)) then recouvr[k]+=1;
                       end;
                    end;
                6: begin           // YO
                   info:=lowercase(nettoie_gj(eclats[6]));
                   // Pour 6, dans 6.
                   for k:=0 to j_max do begin
                       recouvr[k]:=0;
                       if desin[k]<>'' then if pos(desin[k],info)>0 then recouvr[k]+=1;
                       if genre[k]<>'' then if pos(genre[k],info)>0 then recouvr[k]+=1;
                       if p_o_s[k]<>'' then if pos(p_o_s[k],info)>0 then recouvr[k]+=1;
                       end;
                    end;
                7: begin           // PO
                   info:=lowercase(eclats[2]);
                   while (pos('_',info)>0) do
                      info:=copy(info,1,pos('_',info)-1)+copy(info,pos('_',info)+1,length(info));
                    // Pour 7 et 8, elle n'existe pas vraiment...
                    for k:=0 to j_max do begin
                        recouvr[k]:=0;
                        if length(genre[k])=2 then begin
                           str:=': '+copy(genre[k],1,1);
                           if pos(str,info)>0 then recouvr[k]+=1;
                           end;
                        if length(desin[k])>0 then begin
                           if length(desin[k])>1 then
                              str:=copy(desin[k],length(desin[k])-1,2)+' : '
                              else str:=desin[k]+' : ';
                           if pos(str,info)>0 then recouvr[k]+=1;
                           end
                           else if pos(', ',info)=0 then recouvr[k]+=1;
                        if ((p_o_s[k]='adj.')and(copy(info,length(info)-3,4)=' : a')) then recouvr[k]+=1;
                        if ((p_o_s[k]='adv.')and(pos(': adv',info)>0)) then recouvr[k]+=1;
                        if ((p_o_s[k]='verbe')and(pos(': v',info)>0)) then recouvr[k]+=1;
                    end;
                    end;
                8: begin           // WW
                   for k:=0 to j_max do begin
                       recouvr[k]:=0;
                       // Le champ 1 est un nom, 2 un adjectif, 3 et 4 un verbe.
                       if ((eclats[1]<>'')and(genre[k]<>'')) then recouvr[k]+=1;
                       if ((eclats[2]<>'')and(pos('adj.',p_o_s[k])>0)) then recouvr[k]+=1;
                       if p_o_s[k]='verbe' then
                          if ((eclats[3]<>'')or(eclats[4]<>'')) then recouvr[k]+=1;
                       end;
                    end;
           end;  // case
           max:=0;
           for k:=0 to j_max do if recouvr[k]>max then begin
               nvl_place[j]:=k;
               max:=recouvr[k];
               end;
           // Un problème peut venir de deux valeurs égales des recouvrements.
           // Il faudrait être capable d'évaluer le "gain" à faire l'échange.
           j+=1;
       end; // while
       // nvl_place[j] contient le numéro du pilote qui correspond
       for j:=0 to j_max do begin
            k:=nvl_place[j];
            if ((k<>j) and (k>-1) and (echange[9*j+i]=(9*j+i))) then begin
               if ((nvl_place[k]=j) or (nvl_place[k]=-1)) then begin
                  echange[9*k+i]:=9*j+i;
                  echange[9*j+i]:=9*k+i;
                  nvl_place[j]:=-2;
                  nvl_place[k]:=-2;    // J'interdis tout autre changement
                  end
                  else begin
                      // C'est plus compliqué qu'un simple échange j<->k.
                      // J'essaie j->k->l->j
                  l:=nvl_place[k];
                  if ((nvl_place[l]=j) or (nvl_place[l]=-1)) then begin
                     echange[9*l+i]:=9*j+i;
                     echange[9*k+i]:=9*l+i;
                     echange[9*j+i]:=9*k+i;
                     nvl_place[j]:=-2;
                     nvl_place[k]:=-2;
                     nvl_place[l]:=-2;
                     end
                     else OK:=false;
                  end;
            end;
       end;
   end;
   for i:=0 to nn do nvl_lgn[i]:=lgn[echange[i]];
   // Je recopie les lignes en les remettant en ordre.
   for i:=0 to nn do lgn[i]:=nvl_lgn[i];
   range:=OK;
end;

procedure etape3;

var nb_form, nn, pilot:integer;
    OK:boolean;
    ligne_loc : string;
    cnt : array[0..3] of integer;

begin
   for i:=0 to 3 do cnt[i]:=0;
   assign(fic_in,'output/lem_mult2a.csv');
   reset(fic_in);
   assign(fic_out,'output/lem_OK3m.csv');
   rewrite(fic_out);
   assign(rejet,'output/lem_non_tries.txt');
   rewrite(rejet);
   readln(fic_in,ligne_loc);
   repeat
      lem_cour:=copy(ligne_loc,2,length(ligne_loc));
      nn:=0;
      repeat
         readln(fic_in,ligne_loc);
         lgn[nn]:=ligne_loc;
         nn+=1;
      until ((pos('|',ligne_loc)=1) or eof(fic_in));
      // le contenu de la variable ligne_loc sera réutilisé, mieux vaut prendre
      // une variable locale au nom plus protégé
      if eof(fic_in) then nn+=1; // le dernier mot n'a pas de lemme qui suit.
      // Les lgn[i] contiennent l'ensemble des données liées au lemme courant
      // 0, 9 etc... pr le LS ; 1, 10 etc... pr le GJ ;
      nb_mots:=nn div 9;  // c'est le nombre de mots que j'ai.
      i:=nb_mots-1;
      if (lgn[9*i]<>'LS|') then pilot:=0 // le LS mène la danse.
         else if (lgn[9*i+1]<>'GG|') then pilot:=1 // le GG mène la danse.
//         else if (lgn[9*i+2]<>'GJ|') then pilot:=2 // le GJ mène la danse.
  //            else if (lgn[9*i+3]<>'Ge|') then pilot:=3 // le Ge mène la danse.
                   else pilot:=-1;
      if pilot=-1 then begin
         // Je ne sais pas quoi faire
      writeln(rejet,lem_cour);
//         sortie(rejet,nn-2);
{      end
      else begin
//           cnt[pilot]+=1;
         // J'ai un pilote.
         // Je dois déterminer ce qui distingue les homonymes dans le pilote.
         // Puis appliquer ces critères aux autres dicos.
           if range(pilot,nn-2) then sortie(fic_out,nn-2)
                                else sortie(rejet,nn-2);
}      end;
   until eof(fic_in);
//   writeln(rejet,cnt[0],' ',cnt[1],' ',cnt[2],' ',cnt[3]);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(rejet);
end;

procedure etape3bis;

var nb_form, nn, non_vide:integer;
    OK:boolean;
    eclats : tableau;
    ligne_loc : string;
    cnt : array[0..3] of integer;

begin
   for i:=0 to 3 do cnt[i]:=0;
   assign(fic_in,'input/lem_mult3.csv');
   reset(fic_in);
   assign(rejet,'output/lem_mult3b.csv');
   rewrite(rejet);
   readln(fic_in,ligne_loc);
   repeat
      lem_cour:=copy(ligne_loc,2,length(ligne_loc));
      nn:=0;
      repeat
         lgn[nn]:=ligne_loc;
         readln(fic_in,ligne_loc);
         nn+=1;
      until (((pos('|',ligne_loc)=1) and (ord(ligne_loc[length(ligne_loc)])>64))or eof(fic_in));
      // le contenu de la variable ligne_loc sera réutilisé, mieux vaut prendre
      // une variable locale au nom plus protégé
      if eof(fic_in) then nn+=1; // le dernier mot n'a pas de lemme qui suit.
      // Les lgn[i] contiennent l'ensemble des données liées au lemme courant
      // 0, 10 etc... pr les lemmes ; 1, 11 etc... le LS ; 2, 12 etc... pr le GJ ;
      nb_mots:=(nn div 10)-1;  // c'est le nombre de mots que j'ai.
      if nn=20 then begin
         if length(lgn[7])>5 then begin
            lgn[7][2]:='2';
            explose(lgn[7],'|',eclats);
            if pos('2',eclats[2])>1 then begin
               // L'homonyme 2 vient d'abord : je fais l'échange
               lgn[10]:=lgn[0];
               lgn[0]+='2';
               end;
            if length(lgn[17])>5 then lgn[17][2]:='2';
            end
            else if length(lgn[17])>5 then begin
                 lgn[17][2]:='2';
                 // Il n'y a qu'un seul des homonymes dans Collatinus
                 lgn[10]:=lgn[0];
                 lgn[0]+='2';
                 end;
         end
         else begin
            non_vide:=0;
            for i:=0 to nb_mots do if (length(lgn[10*i+7])>5) then non_vide+=1;
            if non_vide=1 then begin
               for i:=0 to nb_mots do if (length(lgn[10*i+7])>5) then begin
                   lgn[10*i+7][2]:='3';
                   lgn[10*i]:=lgn[0];
                   if i>0 then lgn[0]+=chr(48+i);
                end;
            end;
         end;
      for i:=0 to nn-1 do writeln(rejet,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(rejet);
end;

procedure typologie;

var mot: string;
    mots: array[0..60000] of string;
    cnt: array[0..60000] of integer;
    i: integer;

begin
   assign(fic_in,'input/GJ6.csv');
   reset(fic_in);
   assign(fic_out,'output/GJ6_cnt.csv');
   rewrite(fic_out);
//   for i:=0 to 60000 do cnt[i]:=0;
   mots[0]:='';
   cnt[0]:=0;
   nb_mots:=0;
   repeat
      readln(fic_in,ligne);
      if pos('|',ligne)>0 then begin
         ligne:=copy(ligne,pos('|',ligne)+1,length(ligne));
         if pos(':',ligne)>0 then begin
            ligne:=copy(ligne,1,pos(':',ligne)-1);
            while ((pos('(',ligne)>0) and (pos(')',ligne)>pos('(',ligne))) do begin
                 reste:=copy(ligne,pos(')',ligne)+1,length(ligne));
                 ligne:=copy(ligne,1,pos('(',ligne)-1)+reste;
            end;
            while ((pos('[',ligne)>0) and (pos(']',ligne)>pos('[',ligne))) do begin
                 reste:=copy(ligne,pos(']',ligne)+1,length(ligne));
                 ligne:=copy(ligne,1,pos('[',ligne)-1)+reste;
            end;
            if (pos(' ',ligne)>0) then begin
               ligne:=trim(copy(ligne,pos(' ',ligne)+1,length(ligne)));
            // Je ne garde que les lignes contenant un :
            // Je prends ce qui le précède sans ce qui est entre () ou []
            while (pos(' ',ligne)>0) do begin
                 mot:=trim(copy(ligne,1,pos(' ',ligne)-1));
                 ligne:=trim(copy(ligne,pos(' ',ligne)+1,length(ligne)));
                 i:=0;
                 repeat
                    if mot=mots[i] then begin
                       cnt[i]+=1;
                       i:=nb_mots+100;
                       end
                    else i+=1;
                    until i>nb_mots;
                    if (i=nb_mots+1) then begin
                       mots[i]:=mot;
                       cnt[i]:=1;
                       nb_mots:=i;
                       end;
                 end;
            // Il me reste le dernier mot
            if length(trim(ligne))>0 then begin
               mot:=trim(ligne);
               i:=0;
               repeat
                  if mot=mots[i] then begin
                     cnt[i]+=1;
                     i:=nb_mots+100;
                     end
                  else i+=1;
               until i>nb_mots;
               if (i=nb_mots+1) then begin
                  mots[i]:=mot;
                  cnt[i]:=1;
                  nb_mots:=i;
                  end;
               end;
            end;
         end;
      end;
   until eof(fic_in);
   for i:=0 to nb_mots do writeln(fic_out,mots[i],'|',cnt[i]);
   CloseFile(fic_in);
   CloseFile(fic_out);
end;

procedure typologie_Ge;

var mot: string;
    mots: array[0..60000] of string;
    cnt: array[0..60000] of integer;
    i: integer;

begin
   assign(fic_in,'input/Georges2.csv');
   reset(fic_in);
   assign(fic_out,'output/Ge2_cnt.csv');
   rewrite(fic_out);
//   for i:=0 to 60000 do cnt[i]:=0;
   mots[0]:='';
   cnt[0]:=0;
   nb_mots:=0;
   repeat
      readln(fic_in,ligne);
      if pos('|',ligne)>0 then begin
         ligne:=copy(ligne,pos('|',ligne)+1,length(ligne));
         ligne:=copy(ligne,pos('|',ligne)+1,length(ligne));
         ligne:=copy(ligne,1,pos('|',ligne)-1);  // Seult le 3e champ
            while ((pos('(',ligne)>0) and (pos(')',ligne)>pos('(',ligne))) do begin
                 reste:=copy(ligne,pos(')',ligne)+1,length(ligne));
                 ligne:=copy(ligne,1,pos('(',ligne)-1)+reste;
            end;
            while ((pos('[',ligne)>0) and (pos(']',ligne)>pos('[',ligne))) do begin
                 reste:=copy(ligne,pos(']',ligne)+1,length(ligne));
                 ligne:=copy(ligne,1,pos('[',ligne)-1)+reste;
            end;
            while (pos(' ',ligne)>0) do begin
                 mot:=trim(copy(ligne,1,pos(' ',ligne)-1));
                 ligne:=trim(copy(ligne,pos(' ',ligne)+1,length(ligne)));
                 i:=0;
                 repeat
                    if mot=mots[i] then begin
                       cnt[i]+=1;
                       i:=nb_mots+100;
                       end
                    else i+=1;
                    until i>nb_mots;
                    if (i=nb_mots+1) then begin
                       mots[i]:=mot;
                       cnt[i]:=1;
                       nb_mots:=i;
                       end;
                 end;
            // Il me reste le dernier mot
            if length(trim(ligne))>0 then begin
               mot:=trim(ligne);
               i:=0;
               repeat
                  if mot=mots[i] then begin
                     cnt[i]+=1;
                     i:=nb_mots+100;
                     end
                  else i+=1;
               until i>nb_mots;
               if (i=nb_mots+1) then begin
                  mots[i]:=mot;
                  cnt[i]:=1;
                  nb_mots:=i;
                  end;
               end;
            end;
   until eof(fic_in);
   for i:=0 to nb_mots do writeln(fic_out,mots[i],'|',cnt[i]);
   CloseFile(fic_in);
   CloseFile(fic_out);
end;

procedure norm_LS;

var clef,mot,orth,comment: string;
    i: integer;

begin
   assign(fic_in,'input/ls_fini.csv');
   reset(fic_in);
   assign(fic_out,'in_norm/ls_fini_n.csv');
   rewrite(fic_out);
   repeat
      readln(fic_in,ligne);
      clef:=copy(ligne,1,pos('|',ligne)-1);
      ligne:=copy(ligne,pos('|',ligne)+1,length(ligne));
      mot:=copy(ligne,1,pos('|',ligne)-1);
      ligne:=copy(ligne,pos('|',ligne)+1,length(ligne));
      orth:=copy(ligne,1,pos('|',ligne)-1);
      ligne:=copy(ligne,pos('|',ligne)+1,length(ligne));
      comment:=copy(ligne,1,pos('|',ligne)-1);
      ligne:=copy(ligne,pos('|',ligne)+1,length(ligne));
      writeln(fic_out,mot,'|',orth,'|',ligne,'|',clef,'|',comment);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
end;

procedure norm_Lewis;

var clef,mot,orth,comment: string;
    i: integer;

begin
   assign(fic_in,'input/lewis_orig.csv');
   reset(fic_in);
   assign(fic_out,'in_norm/lewis_orig_n.csv');
   rewrite(fic_out);
   repeat
      readln(fic_in,ligne);
      clef:=copy(ligne,1,pos('|',ligne)-1);
      ligne:=copy(ligne,pos('|',ligne)+1,length(ligne));
      writeln(fic_out,ligne,'|',clef);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
end;

procedure norm_GJ;

var clef,mot,info,sens: string;
    i: integer;

begin
   assign(fic_in,'input/GJ6.csv');
   reset(fic_in);
   assign(fic_out,'input/GJ7.csv');
   rewrite(fic_out);
   repeat
      readln(fic_in,ligne);
      if pos(':',ligne)>0 then begin
         // Si la ligne contient un : je vais pouvoir la couper
         // Le GJ6 n'a que 2 champs pour l'instant.
         // Je voudrais en faire 4 : clef,mot,info,sens
         sens:=trim(copy(ligne,pos(':',ligne)+1,length(ligne)));
         clef:=trim(copy(ligne,1,pos('|',ligne)-1));
         ligne:=trim(copy(ligne,1,pos(':',ligne)-1));
         ligne:=trim(copy(ligne,pos('|',ligne)+1,length(ligne)));
         if pos(' ',ligne)>0 then begin
              info:=trim(copy(ligne,pos(' ',ligne)+1,length(ligne)));
              mot:=trim(copy(ligne,1,pos(' ',ligne)-1));
              if mot[length(mot)]=',' then
                 mot:=trim(copy(mot,1,length(mot)-1));
              end
              else begin
              mot:=ligne;
              info:='';
              end;
         writeln(fic_out,clef,'|',mot,'|',info,'|',sens);
      end
      else if pos('|',ligne)>0 then begin
         // Il n'y a pas de :
         // Je sépare le premier mot
         clef:=trim(copy(ligne,1,pos('|',ligne)-1));
         ligne:=trim(copy(ligne,pos('|',ligne)+1,length(ligne)));
         info:='';
         if pos(' ',ligne)>0 then begin
              info:=trim(copy(ligne,pos(' ',ligne)+1,length(ligne)));
              mot:=trim(copy(ligne,1,pos(' ',ligne)-1));
              if mot[length(mot)]=',' then
                 mot:=trim(copy(mot,1,length(mot)-1));
              end
              else mot:=ligne;
              writeln(fic_out,clef,'|',mot,'||',info);
      end
      else writeln(fic_out,ligne);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
end;

procedure test_ordre(nom:string);

var clef, mot : string;

begin
   assign(fic_in,'in_norm/'+nom+'.csv');
   reset(fic_in);
   assign(fic_out,'in_norm/'+nom+'_err.csv');
   rewrite(fic_out);
   mot:='@';
   repeat
      readln(fic_in,ligne);
      clef:=lowercase(copy(ligne,1,pos('|',ligne)-1));
      if clef<mot then writeln(fic_out,ligne);
      mot:=clef;
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);

end;

procedure sep_db;

var clef, mot : string;
    ass1,ass2 : array [0..32] of string;
//    mots, lg : array [0..10000] of string;
    i,n,nb_mots,j:integer;
    OK : boolean;

begin
   assign(fic_in,'input/assimil.csv');
   reset(fic_in);
   i:=0;
   repeat
      readln(fic_in,ligne);
      ass1[i]:=copy(ligne,1,pos('|',ligne)-1);
      ass2[i]:=copy(ligne,pos('|',ligne)+1,length(ligne));
      i+=1;
   until eof(fic_in);
   n:=i-1;
   closefile(fic_in);
   assign(fic_in,'input/lem_Extra4db8o.csv');
   reset(fic_in);
   assign(fic_out,'output/lem_Extra4db13.csv');
   rewrite(fic_out);
   assign(mots,'output/lem_Extra4db14.csv');
   rewrite(mots);
   assign(rejet,'output/lem_Extra4db15.csv');
   rewrite(rejet);
   repeat
      readln(fic_in,ligne);
      if ligne[1]='-' then begin
         writeln(rejet,ligne);
         for i:=1 to 9 do begin
             readln(fic_in,ligne);
             writeln(rejet,ligne);
             end;
         end
      else begin
         OK:=false;
         mot:=copy(ligne,2,length(ligne));
         for i:=0 to n do OK:=OK or (pos(ass1[i],mot)=1);
         if OK then begin
         writeln(mots,ligne);
         for i:=1 to 9 do begin
             readln(fic_in,ligne);
             writeln(mots,ligne);
             end;
         end
      else begin
         writeln(fic_out,ligne);
         for i:=1 to 9 do begin
             readln(fic_in,ligne);
             writeln(fic_out,ligne);
             end;
         end
      end;
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(rejet);
   CloseFile(mots);
end;

procedure moissonne;

begin
   assign(fic_in,'output/lem_Extra4i.csv');
   reset(fic_in);
   assign(fic_out,'output/lem_Extra4i1.csv');
   rewrite(fic_out);
   assign(mots,'output/lem_Extra4i2.csv');
   rewrite(mots);
   assign(rejet,'output/lem_Extra4i3.csv');
   rewrite(rejet);
   repeat
      readln(fic_in,ligne);
      if ligne[1]='|' then begin
         writeln(fic_out,ligne);
         for i:=1 to 9 do begin
             readln(fic_in,ligne);
             writeln(fic_out,ligne);
             end;
         end
      else begin
         if ligne[1]='*' then begin
         writeln(mots,ligne);
         for i:=1 to 9 do begin
             readln(fic_in,ligne);
             writeln(mots,ligne);
             end;
         end
      else begin
         writeln(rejet,ligne);
         for i:=1 to 9 do begin
             readln(fic_in,ligne);
             writeln(rejet,ligne);
             end;
         end
      end;
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(rejet);
   CloseFile(mots);
end;

procedure sep_parfaits;

var j : integer;
    parf : boolean;
    eclats : tableau;

begin
   assign(fic_in,'input/lem_Extra4b.csv');
   reset(fic_in);
   assign(fic_out,'output/lem_Extra4c.csv');
   rewrite(fic_out);
   assign(mots,'output/lem_Extra4i.csv');
   rewrite(mots);
   assign(rejet,'output/lem_Extra4pf.csv');
   rewrite(rejet);
   repeat
      for j:=0 to 9 do readln(fic_in,lgn[j]);
      ligne:=copy(lgn[0],pos('|',lgn[0])+1,length(lgn[0]));
      if pos('=',ligne)>0 then ligne:=copy(ligne,1,pos('=',ligne)-1);
      if ord(ligne[length(ligne)])<64 then ligne:=copy(ligne,1,length(ligne)-1);
      if ((ligne[length(ligne)]='i')and(copy(ligne,length(ligne)-3,4)<>'modi')) then begin
         // ça pourrait être un parfait
         parf:=true;
         if length(lgn[1])>7 then begin
            explose(lgn[1],'|',eclats);
            parf:=(eclats[3]='') and (eclats[4]='') and (eclats[5]='');
            // le LS ne donne pas de parfait ?
            end;
         if length(lgn[2])>7 then begin
                 explose(lgn[2],'|',eclats);
                 parf:=parf and (eclats[3]='') and (eclats[4]='') and (eclats[5]='');
                 if (parf and ((pos('pf.',eclats[6])>0) or (pos('parf',eclats[6])>0)))
                                then lgn[0]:='-'+lgn[0];
            end;
         if ((pos('ōrum',lgn[3])>0)or(pos('m.',lgn[3])>0)) then parf:=false;
         if ((pos('ōrum',lgn[4])>0)or(pos('m.',lgn[4])>0)) then parf:=false;
         if pos('parf.',lgn[3])>0 then  lgn[0]:='-'+lgn[0];
         if pos('parfait',lgn[5])>0 then  lgn[0]:='-'+lgn[0];
         if length(lgn[6])>7 then begin
                 explose(lgn[6],'|',eclats);
                 parf:=parf and (eclats[3]='') and (eclats[4]='') and (eclats[5]='');
            end;
      end
      else parf:=false;
      if parf then begin
                   if (lgn[0][1]='-') then for j:=0 to 9 do writeln(rejet,lgn[j])
                      else for j:=0 to 9 do writeln(mots,lgn[j])
                   end
              else for j:=0 to 9 do writeln(fic_out,lgn[j]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
   CloseFile(rejet);
end;

procedure liste_assimil;

var clef, mot : string;
    ass1,ass2 : array [0..32] of string;
    mots, lg : array [0..10000] of string;
    i,n,nb_mots,j:integer;
    OK : boolean;

begin
   assign(fic_in,'input/assimil.csv');
   reset(fic_in);
   i:=0;
   repeat
      readln(fic_in,ligne);
      ass1[i]:=copy(ligne,1,pos('|',ligne)-1);
      ass2[i]:=copy(ligne,pos('|',ligne)+1,length(ligne));
      i+=1;
   until eof(fic_in);
   n:=i-1;
   closefile(fic_in);
   assign(fic_in,'output/list_lem4db.csv');
   reset(fic_in);
   assign(fic_out,'output/list_doubl4db.csv');
   rewrite(fic_out);
   nb_mots:=-1;
   repeat
      readln(fic_in,ligne);
      clef:=lowercase(copy(ligne,pos('|',ligne)+1,length(ligne)));
      mot:=copy(clef,1,pos('|',clef)-1);
      if (ord(mot[length(mot)])<64) then mot:=copy(mot,1,length(mot)-1);
      // S'il y a un n° d'homonymie, je l'enlève.
      OK:=false;
      for i:=0 to n do begin
      OK:=OK or (pos(ass1[i],mot)=1) or (pos(ass2[i],mot)=1);
      end;
      if OK then begin
         nb_mots+=1;
         lg[nb_mots]:=ligne;
         mots[nb_mots]:=mot;
      end;
      OK:=false;
      // Je dois chercher dans la liste déjà assimilable si j'ai le préfixe assimilé.
      for i:=0 to n do begin
      if pos(ass1[i],mot)=1 then begin
         clef:=ass2[i]+copy(mot,length(ass1[i])+1,length(mot));
         j:=0;
//         while ((mots[j]<>clef) and (j<nb_mots)) do j+=1;
//         if j<nb_mots then begin
         for j:=0 to nb_mots-1 do
             if mots[j]=clef then begin
                      writeln(fic_out,ligne,'|',lg[j]);
                      lg[nb_mots]+='*';
                      lg[j]+='*';
//                      if lg[j][length(lg[j])]<>'*' then lg[j]+='*';
                      end;
         end
      else if pos(ass2[i],mot)=1 then begin
         clef:=ass1[i]+copy(mot,length(ass2[i])+1,length(mot));
         j:=0;
//         while ((mots[j]<>clef) and (j<nb_mots)) do j+=1;
  //       if j<nb_mots then begin
         for j:=0 to nb_mots-1 do
             if mots[j]=clef then begin
                      writeln(fic_out,ligne,'|',lg[j]);
                      lg[nb_mots]+='*';
                      lg[j]+='*';
//                      if lg[j][length(lg[j])]<>'*' then lg[j]+='*';
                      end;
         end;
      end;
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   assign(fic_out,'output/doubl_assim4c.csv');
   rewrite(fic_out);
   for j:=0 to nb_mots do
        if lg[j][length(lg[j])]='*' then writeln(fic_out,lg[j]);
   CloseFile(fic_out);
end;

procedure trie_db(lg:string);

var j : integer;

begin
   ligne:=copy(lg,pos('|',lg)+1,length(lg));
   lg:='|'+copy(ligne,1,pos('|',ligne)-1);
   readln(fic_in,ligne);
   while ((lg[1]<>'|') and not eof(fic_in)) do begin
   writeln(fic_out,'ERREUR|',ligne);
   readln(fic_in,ligne);
   end;
   while ((lg<>ligne) and not eof(fic_in)) do
         for j:=0 to 9 do begin
         writeln(fic_out,ligne);
         readln(fic_in,ligne);
   end;
   if eof(fic_in) then writeln(rejet,'ERREUR',lg)
                  else begin
                       writeln(rejet,ligne);
                       for j:=1 to 9 do begin
                           readln(fic_in,ligne);
                           writeln(rejet,ligne);
                           end;
                       end;
end;

procedure separe_doublons;

var str : string;

begin
   assign(mots,'output/doubl_assim4b.csv');
   reset(mots);
   readln(mots,str);
   assign(fic_in,'input/lem_Coll4.csv');
   reset(fic_in);
   assign(fic_out,'output/lem_Coll4a.csv');
   rewrite(fic_out);
   assign(rejet,'output/lem_Coll4db.csv');
   rewrite(rejet);
   repeat
      trie_db(str);
      readln(mots,str);
   until str[1]='e';
   // Le dernier assimilables de Coll4 est copié. Je dois finir le fichier.
   repeat
      readln(fic_in,ligne);
      writeln(fic_out,ligne);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(rejet);
   assign(fic_in,'input/lem_Extra4.csv');
   reset(fic_in);
   assign(fic_out,'output/lem_Extra4a.csv');
   rewrite(fic_out);
   assign(rejet,'output/lem_Extra4db.csv');
   rewrite(rejet);
   repeat
      trie_db(str);
      readln(mots,str);
   until eof(mots);
   trie_db(str);
   repeat
      readln(fic_in,ligne);
      writeln(fic_out,ligne);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(rejet);
   CloseFile(mots);
end;

procedure compare;

var tab_ls, tab_gg : tableau;
    ligne, mot_ls, mot_gg : string;

begin
   assign(fic_in,'output/lem_OK2a.csv');
   reset(fic_in);
   assign(fic_out,'output/diff_1.csv');
   rewrite(fic_out);
   assign(mots,'output/compatibles.csv');
   rewrite(mots);
   assign(rejet,'output/diff_des.csv');
   rewrite(rejet);
   repeat
      readln(fic_in,ligne);
      relis(fic_in);
      if ((length(lg_ls)>3)and(length(lg_gg)>3)) then begin
         explose(lg_ls,'|',tab_ls);
         explose(lg_gg,'|',tab_gg);
         if tab_ls[2]<>tab_gg[2] then begin
            // Les quantités sont différentes.
            // Je dois vérifier si elles sont compatibles.
            mot_ls:=lowercase(vers_PedeCerto2(tab_ls[2]));
            mot_gg:=lowercase(vers_PedeCerto2(tab_gg[2]));
            if mot_ls<>mot_gg then begin
               writeln(fic_out,ligne,'|',mot_ls,'|',mot_gg);
               ecris(fic_out);
            end
            else begin
                writeln(mots,ligne,'|',mot_ls,'|',mot_gg);
                ecris(mots);
            end;
         end;
         if tab_ls[3]<>tab_gg[3] then begin
            writeln(rejet,ligne,'|',mot_ls,'|',mot_gg);
            ecris(rejet);
            end;
      end;
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verif_Q;

var tab : tableau;
    ligne, mot1 : string;
    lgn, mot : array [0..9] of string;
    i,j : integer;
    egaux : boolean;

begin
   assign(fic_in,'input/lem_Extra5.csv');
   reset(fic_in);
   assign(fic_out,'output/lem_presq5.txt');
   rewrite(fic_out);
   assign(mots,'output/lem_compat5.txt');
   rewrite(mots);
   assign(rejet,'output/lem_diff5.txt');
   rewrite(rejet);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
       for i:=1 to 6 do if ((length(lgn[i])>5)and(i<>5)) then begin
           explose(lgn[i],'|',tab);
           mot[i]:=par_position(tab[2],((i=4)or(i=6)));
           end
          else mot[i]:='';
       // Pour les lignes non vides des dicos avec quantités, j'ai complété les mots
       j:=1;
       while ((mot[j]='')and(j<7)) do j+=1;
       mot1:=mot[j];
       egaux:=true;
       for i:=1 to 6 do lgn[0]+='|'+mot[i];
       for i:=j+1 to 6 do if mot[i]<>'' then egaux:=egaux and (mot1=mot[i]);
       if egaux then for i:=0 to 9 do writeln(mots,lgn[i])
          else if mot[1]=mot[2] then for i:=0 to 9 do writeln(fic_out,lgn[i])
                  else for i:=0 to 9 do writeln(rejet,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
   CloseFile(rejet);
end;

procedure verif_Q2;

var tab : tableau;
    ligne, mot1, mot_ref : string;
    lgn, mot : array [0..9] of string;
    i,j : integer;
    egaux, ls_gg : boolean;

begin
   assign(fic_in,'input/lem_Extra5.csv');
   reset(fic_in);
   assign(fic_out,'output/lem_presq5b.txt');
   rewrite(fic_out);
   assign(mots,'output/lem_compat5b.txt');
   rewrite(mots);
   assign(rejet,'output/lem_diff5b.txt');
   rewrite(rejet);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
       mot_ref:=copy(lgn[0],pos('|',lgn[0])+1,length(lgn[0]));
       if pos('=', mot_ref)>0 then
          mot_ref:=copy(mot_ref,1,pos('=',mot_ref)-1);
       if ord(mot_ref[length(mot_ref)])<64 then
          mot_ref:=copy(mot_ref,1,length(mot_ref)-1);
       for i:=1 to 6 do if ((length(lgn[i])>5)and(i<>5)) then begin
           explose(lgn[i],'|',tab);
           mot[i]:=coupe(tab[2]);
{           if ((pos(' ',tab[2])>0)and(pos(' -',tab[2])=0)) then
              mot[i]:=copy(tab[2],1,pos(' ',tab[2])-1)
              else mot[i]:=tab[2];
           if pos('(',mot[i])>0 then
              mot[i]:=copy(mot[i],1,pos('(',mot[i])-1)+copy(mot[i],pos(')',mot[i])+1,length(mot[i]));
}
{           if ((length(mot_ref)<>length(tab[1])) and (pos('=',lgn[0])>0)) then begin
                   // Par un malheur d'assimilation, les formes sont différentes
                   mot1:=tab[2];
                   j:=1;
                   while (mot_ref[j]=mot1[j]) do j+=1; // la lettre j diffère.
                   if length(mot_ref)>length(mot1) then
                      mot[i]:=copy(mot_ref,1,j)+copy(mot1,j,length(mot1))
                   else
                      mot[i]:=copy(mot1,1,j-1)+copy(mot1,j+1,length(mot1));
              end;  }
           end
          else mot[i]:='';
       // Pour les lignes non vides des dicos avec quantités, j'ai les mots
       j:=1;
       while ((mot[j]='')and(j<7)) do j+=1;
       mot1:=mot[j];
       ls_gg:=true;
       if ((j=1) and (mot[2]<>'')) then begin
          ls_gg:=compatible(mot[1],mot[2],mot1);
          j:=2;
          end;
       egaux:=ls_gg;
//       for i:=1 to 6 do lgn[0]+='|'+mot[i];
       for i:=j+1 to 6 do if mot[i]<>'' then begin
           mot[0]:=mot1;
           egaux:=egaux and compatible(mot[0],mot[i],mot1);
           end;
       if mot1<>'' then begin
          lgn[0]+='|'+mot1+'|'+par_position(mot1,false);
          if mot_ref<>lowercase(nettoie_gj(mot1)) then lgn[0]+='§§§';
       end
       else lgn[0]+='||';
       if egaux then for i:=0 to 9 do writeln(mots,lgn[i])
          else if ls_gg then for i:=0 to 9 do writeln(fic_out,lgn[i])
                  else for i:=0 to 9 do writeln(rejet,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
   CloseFile(rejet);
end;

procedure etablir_Q;

var tab : tableau;
    ligne, mot1, mot0, mot_ref, num : string;
    lgn, mot, mm : array [0..9] of string;
    i,j, c_max, i_max, premier : integer;
    egaux, ls_gg, non_vides : boolean;
    comp : array [1..6] of integer;

begin
   assign(fic_in,'input/lem_Extra5.csv');
   reset(fic_in);
   assign(fic_out,'output/lem_Extra6_new.txt');
   rewrite(fic_out);
   assign(mots,'output/lem_mots6.txt');
   rewrite(mots);
   assign(rejet,'output/lem_diff6.txt');
   rewrite(rejet);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
       mot_ref:=copy(lgn[0],2,length(lgn[0]));
       num:=''; // par défaut le numéro d'homonymie est ''
       if pos('=', mot_ref)>0 then
          mot_ref:=copy(mot_ref,1,pos('=',mot_ref)-1);
       if ord(mot_ref[length(mot_ref)])<64 then begin
          num:=mot_ref[length(mot_ref)]; // 2 ou plus
          mot_ref:=copy(mot_ref,1,length(mot_ref)-1);
       end;
       for i:=1 to 6 do if ((length(lgn[i])>5)and(i<>5)) then begin
           explose(lgn[i],'|',tab);
           mot[i]:=coupe(tab[2]);
           end
          else mot[i]:='';
       if length(lgn[8])>5 then begin
                  explose(lgn[8],'|',tab);
//                  mot[5]:=PO_utf(tab[2]); // Je remets PO en case 5.
                  end;
       // Pour les lignes non vides des dicos avec quantités, j'ai les mots
       non_vides:=(mot[1]<>'') and (mot[2]<>'');
       if non_vides then begin
               ls_gg:=compatible(mot[1],mot[2],mot1);
               // Le L&S et le Gaffiot existent et sont comparés.
               egaux:=false; // Inutile de tester les autres.
               premier:=1;
               end
          else begin
               ls_gg:=false; // Non-existants
               egaux:=true;
               j:=1;
               while ((mot[j]='')and(j<7)) do j+=1;
               mot1:=mot[j];
               premier:=j;
               for i:=j+1 to 6 do if mot[i]<>'' then begin
                   mot[0]:=mot1;
                   egaux:=egaux and compatible(mot[0],mot[i],mot1);
                   end;
       end;
          // Si les entrées sont compatibles, j'ai fini...
       if not(egaux or ls_gg) then begin
          // Entrées incompatibles : je dois choisir...
          for i:=1 to 6 do comp[i]:=0;
          c_max:=-5;
          i_max:=0;
          for i:=1 to 6 do if (mot[i]<>'') then begin
              mot1:=mot[i];
              for j:=1 to 6 do
              if ((i<>j) and (mot[j]<>'')) then begin
                 mot0:=mot1;
                 if compatible(mot0,mot[j],mot1) then comp[i]+=1;
              end;
              mm[i]:=mot1;
              if (comp[i]>c_max) then begin
                 c_max:=comp[i];
                 i_max:=i;
              end;
          end;
          // J'ai compté les formes compatibles avec mm[i].
          // i_max a fait le meilleur score.
          mot1:=mm[i_max];
       end;
       // mot1 est le mot avec toutes les quantités retenues.
       if mot1<>'' then begin
          lgn[0]+='|'+mot1+num+'|'+par_position(mot1,i_max>3);
          if mot_ref<>lowercase(nettoie_gj(mot1)) then lgn[0]+='§§§';
       end
       else lgn[0]+='||';
       for i:=0 to 9 do writeln(fic_out,lgn[i]); // Tout est ressorti.
       if not(egaux or ls_gg) then begin
          for i:=0 to 9 do writeln(rejet,mot[i],'|',lgn[i]); // Pour comprendre les différences.
          writeln(mots,lgn[0],'|',i_max,'|',c_max); // Pour une vérification rapide.
       end;
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
   CloseFile(rejet);
end;

function subst(f_fin,f_genitif,f_genre:string):boolean;

// Vérifie si le bloc correspond à un substantif se terminant par f_fin
// avec le génitif f_genitif et le genre f_genre.

var tab : tableau;
    ligne, mot_ref, num, gen, f_genitif2 : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;
    OK: boolean;

begin
   f_genitif2:=f_genitif+', ';
   mot_ref:=copy(lgn[0],2,length(lgn[0]));
   mot_ref:=copy(mot_ref,1,pos('|',mot_ref)-1);
   num:=''; // par défaut le numéro d'homonymie est ''
   if pos('=', mot_ref)>0 then
      mot_ref:=copy(mot_ref,1,pos('=',mot_ref)-1);
   if ord(mot_ref[length(mot_ref)])<64 then begin
      num:=mot_ref[length(mot_ref)]; // 2 ou plus
      mot_ref:=copy(mot_ref,1,length(mot_ref)-1);
   end;
   OK:=false;
   if copy(mot_ref,length(mot_ref)-length(f_fin)+1,length(f_fin))=f_fin then begin
      // Le mot se termine par a : première déclinaison ?
      genitif:=0;
      genre:=0;
      // Génitif en ae et genre m. ou f.
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
          explose(lgn[i],'|',tab);
          if ((i=3)or(i=4)) then begin
             if (pos(f_genitif2,nettoie_gj(tab[3]))>0) then genitif+=1;
             if (pos(f_genre,tab[3])>0) then genre+=1;
          end
          else begin
          if (nettoie_gj(tab[3])=f_genitif) then genitif+=1;
          if (pos(tab[4],f_genre)>0) then begin
                                     genre+=1;
                                     if gen='' then gen:=tab[4];
                                     end;
          end;
      end;
      OK:=((genre>0)and(genitif>0));
   end;
   subst:=OK;
end;

function adj(f_fin,f_genitif:string):boolean;

// Vérifie si le bloc correspond à un substantif se terminant par f_fin
// avec la seconde forme f_genitif

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;
    OK: boolean;

begin
   mot_ref:=copy(lgn[0],2,length(lgn[0]));
   mot_ref:=copy(mot_ref,1,pos('|',mot_ref)-1);
   num:=''; // par défaut le numéro d'homonymie est ''
   if pos('=', mot_ref)>0 then
      mot_ref:=copy(mot_ref,1,pos('=',mot_ref)-1);
   if ord(mot_ref[length(mot_ref)])<64 then begin
      num:=mot_ref[length(mot_ref)]; // 2 ou plus
      mot_ref:=copy(mot_ref,1,length(mot_ref)-1);
   end;
   OK:=false;
   if copy(mot_ref,length(mot_ref)-length(f_fin)+1,length(f_fin))=f_fin then begin
      // Le mot se termine par a : première déclinaison ?
      genitif:=0;
      genre:=0;
      // Génitif en ae et genre m. ou f.
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
          explose(lgn[i],'|',tab);
          if (tab[3]=f_genitif) then genitif+=1;
      end;
      OK:=(genitif>0);
   end;
   adj:=OK;
end;

procedure a_ae;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_a_ae.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('a','ae','f.') then begin
                          lgn[0]+='|0|||ae, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('a','ae','m.') then begin
                          lgn[0]+='|0|||ae, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure as_ae;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_as_ae.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('as','ae','f.') then begin
                          lgn[0]+='|100|||ae, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('as','ae','m.') then begin
                          lgn[0]+='|100|||ae, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure es_ae;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_es_ae.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('es','ae','f.') then begin
                          lgn[0]+='|101|||ae, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('es','ae','m.') then begin
                          lgn[0]+='|101|||ae, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure e_es;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_e_es.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('e','es','f.') then begin
                          lgn[0]+='|102|||es, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('e','es','m.') then begin
                          lgn[0]+='|102|||es, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure ae_arum;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_ae_arum.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('ae','arum','f.') then begin
                          lgn[0]+='|0|||arum, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('ae','arum','m.') then begin
                          lgn[0]+='|0|||arum, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure i_orum;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_i_orum.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('i','orum','f.') then begin
                          lgn[0]+='|1|||orum, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('i','orum','m.') then begin
                          lgn[0]+='|1|||orum, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure a_orum;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_a_orum.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('a','orum','n.') then begin
                          lgn[0]+='|4|||orum, n.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure ia_ium;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_ia_ium.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('ia','ium','n.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3])-1,2)='ia' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-2)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-3);
                          lgn[0]+='|8|'+mot_ref+'||ium, n.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure es_ium;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_es_ium.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('es','ium','m.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3])-1,2)='es' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-2)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-3);
                          lgn[0]+='|6|'+mot_ref+'||ium, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('es','ium','f.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3])-1,2)='es' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-2)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-3);
                          lgn[0]+='|6|'+mot_ref+'||ium, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure es_um;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_es_um.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('es','um','m.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3])-1,2)='es' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-2)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-3);
                          lgn[0]+='|5|'+mot_ref+'||um, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('es','um','f.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3])-1,2)='es' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-2)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-3);
                          lgn[0]+='|5|'+mot_ref+'||um, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure es_is;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_es_is.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('es','is','m.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3])-1,2)='es' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-2)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-3);
                          lgn[0]+='|6|'+mot_ref+'||is, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('es','is','f.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3])-1,2)='es' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-2)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-3);
                          lgn[0]+='|6|'+mot_ref+'||is, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure es_ei;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_es_ei.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('es','ei','m.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3])-1,2)='es' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-2)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-3);
                          lgn[0]+='|10|||ei, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('es','ei','f.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3])-1,2)='es' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-2)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-3);
                          lgn[0]+='|10|||ei, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure is_is;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_is_is.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('is','is','m.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3])-1,2)='is' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-2)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-3);
                          lgn[0]+='|6|'+mot_ref+'||is, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('is','is','f.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3])-1,2)='is' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-2)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-3);
                          lgn[0]+='|6|'+mot_ref+'||is, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else begin
                         for i:=0 to 9 do writeln(mots,lgn[i]);
                         CloseFile(mots);
                         append(mots);
                     end;
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure e_is;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_e_is.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('e','is','n.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3]),1)='e' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-1)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-2);
                          lgn[0]+='|8|'+mot_ref+'||is, n.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure a_um;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_a_um.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('a','um','n.') then begin
                          explose(lgn[0],'|',tab);
                          if copy(tab[3],length(tab[3]),1)='a' then
                             mot_ref:=copy(tab[3],1,length(tab[3])-1)
                             else mot_ref:=copy(tab[3],1,length(tab[3])-2);
                          lgn[0]+='|7|'+mot_ref+'||um, n.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure os_i;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_os_i.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('ios','ii','f.') then begin
                          lgn[0]+='|103|||ii, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('ios','ii','m.') then begin
                          lgn[0]+='|103|||ii, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('os','i','f.') then begin
                          lgn[0]+='|103|||i, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('os','i','m.') then begin
                          lgn[0]+='|103|||i, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure us_i;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;
    grec_simple:boolean;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_us_i.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('ius','ii','f.') then begin
                          lgn[0]+='|1|||ii, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('ius','ii','m.') then begin
                          lgn[0]+='|1|||ii, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('us','i','f.') then begin
                          lgn[0]+='|1|||i, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('us','i','m.') then begin
          // Je dois vérifier si ce n'est pas un grec du modèle 105
          if ((pos('eus',lgn[0])>0)or(pos('eus2',lgn[0])>0)) then begin
             explose(lgn[0],'|',tab);
             grec_simple:=(copy(tab[2],length(tab[2])-2,3)='eus')
                          and (copy(tab[2],length(tab[2])-3,4)<>'aeus');
             grec_simple:=grec_simple or((copy(tab[2],length(tab[2])-3,4)='eus2')
                          and (copy(tab[2],length(tab[2])-4,5)<>'aeus2'));
             grec_simple:=grec_simple or(copy(tab[2],length(tab[2])-3,4)='ēus');
             grec_simple:=grec_simple or(copy(tab[2],length(tab[2])-4,5)='ēus2');
             if grec_simple then lgn[0]+='|105|||ĕi (ĕos), m.'
                else if copy(tab[2],length(tab[2])-3,4)='eūs' then begin
                     lgn[0]:='|'+tab[1]+'|';
                     lgn[0]+=copy(tab[2],1,length(tab[2])-4)+'ēus|';
                     lgn[0]+=copy(tab[3],1,length(tab[3])-5)+'ēus|105|||ĕi (ĕos), m.';
                     end
             else if copy(tab[2],length(tab[2])-4,5)='eūs2' then begin
                  lgn[0]:='|'+tab[1]+'|';
                  lgn[0]+=copy(tab[2],1,length(tab[2])-5)+'ēus2|';
                  lgn[0]+=copy(tab[3],1,length(tab[3])-6)+'ēus2|105|||ĕi (ĕos), m.';
                  end
             else lgn[0]+='|1|||i, m.';
          end
                         else lgn[0]+='|1|||i, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure us_us;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_us_us.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('us','us','f.') then begin
                          lgn[0]+='|9|||us, f.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('us','us','m.') then begin
                          lgn[0]+='|9|||us, m.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure on_i;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_on_i.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('ion','ii','n.') then begin
                          lgn[0]+='|104|||ii, n.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('on','i','n.') then begin
                          lgn[0]+='|104|||i, n.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure um_i;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_um_i.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if subst('ium','ii','n.') then begin
                          lgn[0]+='|4|||ii, n.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
          else if subst('um','i','n.') then begin
                          lgn[0]+='|4|||i, n.';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure us_a_um;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_us_a_um.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if adj('us','a, um') then begin
                          lgn[0]+='|11|||a, um';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verbes;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;
    verbe: boolean;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'output/lem6_verbes.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
       verbe:=false;
       if pos('||v.',lgn[1])>0 then begin
          // Le L&S indique v. dans le POS
          explose(lgn[1],'|',tab);
          verbe:=(pos('v.',tab[5])=1);
                        end;
       if pos('tr.|',lgn[2])>0 then begin
          // Le Gaffiot indique tr. ou intr. dans le POS
          explose(lgn[2],'|',tab);
          verbe:=verbe or (pos('tr.',tab[5])>0);
                     end;
       if pos('tr. -',lgn[3])>0 then begin
          // Le Gaffiot indique tr. ou intr. dans le POS
          explose(lgn[3],'|',tab);
          verbe:=verbe or (pos('tr. -',tab[4])>0);
                     end;
       if not verbe then for i:=1 to 6 do if length(lgn[i])>5 then begin
          explose(lgn[i],'|',tab);
          if pos('us sum', tab[3])>0 then verbe:=true;
          if ((copy(tab[1],length(tab[1])-2,3)='fio') and
           (pos('ieri',nettoie_gj(tab[3]))>0)) then verbe:=true;
          if ((copy(tab[1],length(tab[1]),1)='o') and
           (pos(lowercase(nettoie_gj(tab[3])),'are ere ire')>0)) then verbe:=true;
          if ((copy(tab[1],length(tab[1])-1,2)='or') and
           (pos(lowercase(nettoie_gj(tab[3])),'ari eri iri')>0)) then verbe:=true;
       end;
       if verbe then for i:=0 to 9 do writeln(fic_out,lgn[i])
                else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure adverbes;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;
    adverbe, OK, conj, prep, interj : boolean;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_invar.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
       adverbe:=false;
       conj:=false;
       prep:=false;
       interj:=false;
       for i:=1 to 6 do if length(lgn[i])>5 then begin
          if pos('adv.', lgn[i])>0 then adverbe:=true;
          if pos('Adv.', lgn[i])>0 then adverbe:=true;
          if pos('conj.', lgn[i])>0 then conj:=true;
          if pos('Coni.', lgn[i])>0 then conj:=true;
          if pos('prep.', lgn[i])>0 then prep:=true;
          if pos('praep.', lgn[i])>0 then prep:=true;
          if pos('Praep.', lgn[i])>0 then prep:=true;
          if pos('interj.', lgn[i])>0 then interj:=true;
          if pos('Interj.', lgn[i])>0 then interj:=true;
       end;
       OK:=adverbe or conj or prep or interj;
       if OK then lgn[0]+='|30|||';
       if adverbe then lgn[0]+='adv. ';
       if prep then lgn[0]+='prep. ';
       if conj then lgn[0]+='conj. ';
       if interj then lgn[0]+='interj. ';
       if OK then lgn[0]:=copy(lgn[0],1,length(lgn[0])-1);
       if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
             else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure indecl;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;
    adverbe, OK, conj, prep, interj : boolean;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_indecl.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
       adverbe:=false;
       conj:=false;
       prep:=false;
       interj:=false;
       for i:=1 to 6 do if length(lgn[i])>5 then begin
          if pos('indecl.', lgn[i])>0 then adverbe:=true;
          if pos('indécl.', lgn[i])>0 then adverbe:=true;
          if pos('invar.', lgn[i])>0 then adverbe:=true;
          if pos(' f.', lgn[i])>0 then conj:=true;
          if pos(' m.', lgn[i])>0 then prep:=true;
          if pos(' n.', lgn[i])>0 then interj:=true;
          if pos('|f.', lgn[i])>0 then conj:=true;
          if pos('|m.', lgn[i])>0 then prep:=true;
          if pos('|n.', lgn[i])>0 then interj:=true;
       end;
       if adverbe then begin lgn[0]+='|30|||indecl. ';
          if prep then lgn[0]+='m. ';
          if conj then lgn[0]+='f. ';
          if interj then lgn[0]+='n. ';
          lgn[0]:=copy(lgn[0],1,length(lgn[0])-1);
       end;
       if adverbe then for i:=0 to 9 do writeln(fic_out,lgn[i])
             else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure formes_en_er;

var tab : tableau;
    ligne, mot_ref, num, gen, t3, mot1, mot2, lett : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;
    adject, OK, avec_e : boolean;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_er.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
       mot_ref:=copy(lgn[0],2,length(lgn[0]));
       mot_ref:=copy(mot_ref,1,pos('|',mot_ref)-1);
       num:=''; // par défaut le numéro d'homonymie est ''
       if pos('=', mot_ref)>0 then
          mot_ref:=copy(mot_ref,1,pos('=',mot_ref)-1);
       if ord(mot_ref[length(mot_ref)])<64 then begin
          num:=mot_ref[length(mot_ref)]; // 2 ou plus
          mot_ref:=copy(mot_ref,1,length(mot_ref)-1);
       end;
       OK:=false;
       if copy(mot_ref,length(mot_ref)-1,2)='er' then begin
          // Le mot se termine par er ?
          explose(lgn[0],'|',tab);
          t3:=tab[3];
          mot1:=t3;
          if t3<>'' then begin
          if t3[length(t3)-1]='e' then begin
           //  mot1:=copy(t3,1,length(t3)-2);
             mot2:=copy(t3,1,length(t3)-3);
             lett:=t3[length(t3)-2];
          end
          else begin
           //   mot1:=copy(t3,1,length(t3)-3);
              mot2:=copy(t3,1,length(t3)-4);
              lett:=t3[length(t3)-3];
          end;
          adject:=false;
          avec_e:=false;
          // Génitif en eri ou en ?ri et genre m. ou f.
          // ou adjectif avec deux formes "era, erum" ou "?ra, ?rum" ou "a, um"
          for i:=1 to 6 do
              if ((length(lgn[i])>5)and(i<>5)) then begin
              explose(lgn[i],'|',tab);
              t3:=nettoie_gj(tab[3]);
              if t3<>'' then OK:=true;
              if ((pos('a,',t3)>0)and(pos('um',t3)>0)) then adject:=true;
              if ((pos('era,',t3)>0)or(pos('erum',t3)>0)or(pos('eri',t3)>0))
                 then avec_e:=true;
              if ((i=3)or(i=4)) then begin
                 if ((not adject)and(gen='')and(pos(', ',t3)>0))
                    then gen:=copy(t3,pos(', ',t3)+2,length(t3));
              end
              else begin
                   if ((not adject)and(gen='')) then gen:=tab[4];
              end;
          end;
          if OK then begin
          if adject then begin
             if avec_e then lgn[0]+='|12|'+mot1+'||era, erum'
                else lgn[0]+='|13|'+rend_commune(mot2)+lett+'r||'+lett+'ra, '+lett+'rum';
          end
          else begin
             if avec_e then lgn[0]+='|2|'+mot1+'||eri, '+gen
                else lgn[0]+='|3|'+rend_commune(mot2)+lett+'r||'+lett+'ri, '+gen;
          end;
          end;
          end;
       end;
       if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
             else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure decl3;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre, adjectif : integer;
    adj, subs: boolean;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'output/lem6_3e_decl.txt');
   rewrite(fic_out);
   assign(rejet,'output/lem6_2e_cl.txt');
   rewrite(rejet);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
       adjectif:=0;
       genitif:=0;
       genre:=0;
       // Je cherche un lemme dont la 2e forme se termine par is sans être is
       for i:=1 to 6 do if ((length(lgn[i])>5)and(i<>5)) then begin
           explose(lgn[i],'|',tab);
           gen:=nettoie_gj(tab[3]);
           if (pos('is',gen)>0) then begin
              if ((i=3)or(i=4)) then begin
                 if pos(',',gen)=0 then begin
                    adjectif+=1;
                    if length(gen)>2 then genitif+=1;
                 end
                 else begin
                 if ((pos('m.',gen)>0)or(pos('f.',gen)>0)or(pos('n.',gen)>0)) then genre+=1;
                    if pos(',',gen)>3 then genitif+=1;
                 end
              end
              else if length(gen)>2 then begin
                  genitif+=1;
                  if (length(tab[4])>0) then genre+=1;
                  if lowercase(tab[5])='adj.' then adjectif+=1;
              end;
           end;
       end;
       adj:=false;
       subs:=false;
       if genitif>0 then begin
          if genre=0 then adj:=true
          else subs:=true;
       end;
       if adj then for i:=0 to 9 do writeln(rejet,lgn[i])
       else if subs then for i:=0 to 9 do writeln(fic_out,lgn[i])
                else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(rejet);
   CloseFile(mots);
end;

procedure is_e;

var tab : tableau;
    ligne, mot_ref, num, gen : string;
//    lgn : array [0..9] of string;
    i, genitif, genre : integer;

begin
   assign(fic_in,'output/lem_Extra6'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_is_e.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem_Extra6'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
       for i:=0 to 9 do readln(fic_in,lgn[i]);
       // J'ai lu un bloc
          if adj('is','e') then begin
                           explose(lgn[0],'|',tab);
                           if copy(tab[3],length(tab[3])-1,2)='is' then
                              mot_ref:=copy(tab[3],1,length(tab[3])-2)
                              else mot_ref:=copy(tab[3],1,length(tab[3])-3);
                          lgn[0]+='|14|'+mot_ref+'||e';
                          for i:=0 to 9 do writeln(fic_out,lgn[i])
                     end
                     else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure compte_lettres;

var compt : array [0..31] of integer;
    i : integer;

begin
   assign(fic_in,'input/Cic_de_amicitia_voc_alf.txt');
   reset(fic_in);
   assign(fic_out,'output/lettres_lat_Cic_de_amic.csv');
   rewrite(fic_out);
   for i:=0 to 31 do compt[i]:=0;
   repeat
         readln(fic_in,ligne);
//         ligne:=copy(ligne,1,pos(' ',ligne)-1);
//         for i:=1 to pos(' ',ligne)-1 do compt[ord(ligne[i])-64]+=1;
//         for i:=1 to length(ligne) do compt[ord(ligne[i])-96]+=1;
         for i:=1 to pos(' ',ligne)-1 do compt[ord(ligne[i])-96]+=1;
   until eof(fic_in);
   for i:=1 to 26 do writeln(fic_out,chr(64+i),';',compt[i]);
   CloseFile(fic_in);
   CloseFile(fic_out);
end;

procedure etape7;

begin
   numero:=96;
   us_a_um;
   is_e;
   verbes;
   decl3;
   a_ae;
   a_orum;
   ia_ium;
   a_um;
   ae_arum;
   us_i;
   i_orum;
   um_i;
   on_i;
   os_i;
   as_ae;
   es_ae;
   e_es;
   e_is;
   es_ium;
   es_um;
   es_is;
   us_us;
   es_ei;
   adverbes;
   indecl;
   formes_en_er;
   is_is;
end;

procedure typ_decl_3;

var mot: string;
    mots: array[0..60000] of string;
    cnt: array[0..60000] of integer;
    i, j: integer;
    tab: tableau;

begin
   assign(fic_in,'output/lem6_3e_decl.txt');
   reset(fic_in);
   assign(fic_out,'output/decl3_cnt.csv');
   rewrite(fic_out);
//   for i:=0 to 60000 do cnt[i]:=0;
   mots[0]:='';
   cnt[0]:=0;
   nb_mots:=0;
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=tab[3];
             if pos(',',mot)>0 then mot:=copy(mot,1,pos(',',mot)-1);
             j:=0;
          repeat
             if mot=mots[j] then begin
                cnt[j]+=1;
                j:=nb_mots+100;
                end
                else j+=1;
          until j>nb_mots;
          if (j=nb_mots+1) then begin
             mots[j]:=mot;
             cnt[j]:=1;
             nb_mots:=j;
             end;
          end;
   until eof(fic_in);
   for i:=0 to nb_mots do writeln(fic_out,mots[i],'|',cnt[i]);
   CloseFile(fic_in);
   CloseFile(fic_out);
end;

procedure typ_cl_2;

var mot: string;
    mots: array[0..60000] of string;
    cnt: array[0..60000] of integer;
    i, j: integer;
    tab: tableau;

begin
   assign(fic_in,'output/lem6_2e_cl.txt');
   reset(fic_in);
   assign(fic_out,'output/cl2_cnt.csv');
   rewrite(fic_out);
//   for i:=0 to 60000 do cnt[i]:=0;
   mots[0]:='';
   cnt[0]:=0;
   nb_mots:=0;
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=tab[3];
             if pos(',',mot)>0 then mot:=copy(mot,1,pos(',',mot)-1);
             j:=0;
          repeat
             if mot=mots[j] then begin
                cnt[j]+=1;
                j:=nb_mots+100;
                end
                else j+=1;
          until j>nb_mots;
          if (j=nb_mots+1) then begin
             mots[j]:=mot;
             cnt[j]:=1;
             nb_mots:=j;
             end;
          end;
   until eof(fic_in);
   for i:=0 to nb_mots do writeln(fic_out,mots[i],'|',cnt[i]);
   CloseFile(fic_in);
   CloseFile(fic_out);
end;

procedure onis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_onis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('onis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('o|',lgn[0])=0) and (pos('on|',lgn[0])=0);
      toto:=toto and (pos('o2|',lgn[0])=0) and (pos('on2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|onis');
         if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
            then mdl:='|5|'
            else mdl:='|7|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par o ou on.
         if mot[length(mot)]='n' then mot:=copy(mot,1,length(mot)-1);
         if mot[length(mot)]='o' then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure oris;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_oris.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('oris',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;

          end;
      if OK then begin
      toto:=(pos('r|',lgn[0])=0) and (pos('s|',lgn[0])=0);
      toto:=toto and (pos('r2|',lgn[0])=0) and (pos('s2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|oris');
         if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
            then mdl:='|5|'
            else mdl:='|7|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par or ou us.
         if ((mot[length(mot)]='r')or(mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='o')or(mot[length(mot)]='u'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure atis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_atis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('atis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('a|',lgn[0])=0) and (pos('as|',lgn[0])=0);
      toto:=toto and (pos('a2|',lgn[0])=0) and (pos('as2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|atis');
         if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
            then mdl:='|5|'
            else mdl:='|7|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par a, as ou ar.
         if ((mot[length(mot)]='r')or(mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='a'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure idis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_idis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('idis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('a|',lgn[0])=0) and (pos('is|',lgn[0])=0);
      toto:=toto and (pos('a2|',lgn[0])=0) and (pos('is2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|idis');
         if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
            then mdl:='|5|'
            else mdl:='|7|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par is.
         if ((mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='i'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure icis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_icis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('icis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('x|',lgn[0])=0) and (pos('x2|',lgn[0])=0);
//      toto:=toto and (pos('a2|',lgn[0])=0) and (pos('is2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|icis');
         if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
            then mdl:='|5|'
            else mdl:='|7|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par ix.
         if ((mot[length(mot)]='x'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='i'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure inis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_inis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('inis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('en|',lgn[0])=0) and (pos('o|',lgn[0])=0);
      toto:=toto and (pos('en2|',lgn[0])=0) and (pos('o2|',lgn[0])=0);
      toto:=toto and (pos('in|',lgn[0])=0) and (pos('is|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|inis');
         if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
            then mdl:='|5|'
            else mdl:='|7|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par en,in, is ou o.
         if ((mot[length(mot)]='n')or(mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='i')or(mot[length(mot)]='e')or(mot[length(mot)]='o'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure adis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_adis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('adis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('as|',lgn[0])=0) and (pos('as2|',lgn[0])=0);
//      toto:=toto and (pos('en2|',lgn[0])=0) and (pos('o2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|adis');
         if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
            then mdl:='|5|'
            else mdl:='|7|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par en,in, is ou o.
         if ((mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='a'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure ontis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_ontis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('ontis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('on|',lgn[0])=0) and (pos('ons|',lgn[0])=0);
      toto:=toto and (pos('on2|',lgn[0])=0) and (pos('ons2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|ontis');
         if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
            then mdl:='|6|'
            else mdl:='|8|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par en,in, is ou o.
         if ((mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='n'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='o'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+='ōnt';
{         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);  }
         lgn[0]+=mdl+mot+'||ontis, '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure antis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_antis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('antis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('as|',lgn[0])=0) and (pos('ans|',lgn[0])=0);
      toto:=toto and (pos('as2|',lgn[0])=0) and (pos('ans2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|antis');
      if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
         then mdl:='|6|'
         else mdl:='|8|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par en,in, is ou o.
         if ((mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='n'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='a'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+='ānt';
{         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);  }
         lgn[0]+=mdl+mot+'||antis, '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure entis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_entis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('entis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('ens2|',lgn[0])=0) and (pos('ens|',lgn[0])=0);
//      toto:=toto and (pos('en2|',lgn[0])=0) and (pos('o2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|entis');
      if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
         then mdl:='|6|'
         else mdl:='|8|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités.
         if pos('is|',lgn[0])=0 then begin
         if ((mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='n'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='e'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         end
         else begin
                 if ((mot[length(mot)-1]='i'))
                    then mot:=copy(mot,1,length(mot)-4)
                    else mot:=copy(mot,1,length(mot)-3);
         end;
         mot+='ēnt';
{         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);  }
         lgn[0]+=mdl+mot+'||entis, '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure untis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_untis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('untis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('us|',lgn[0])=0) and (pos('uns|',lgn[0])=0);
      toto:=toto and (pos('us2|',lgn[0])=0) and (pos('uns2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|untis');
      if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
         then mdl:='|6|'
         else mdl:='|8|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par en,in, is ou o.
         if ((mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='n'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='u'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+='ūnt';
{         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);  }
         lgn[0]+=mdl+mot+'||untis, '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure acis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_acis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('acis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('ax|',lgn[0])=0) and (pos('ax2|',lgn[0])=0);
//      toto:=toto and (pos('en2|',lgn[0])=0) and (pos('o2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|acis');
         if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
            then mdl:='|5|'
            else mdl:='|7|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par en,in, is ou o.
         if ((mot[length(mot)]='x'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='a'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure eris;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_eris.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('eris',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('er|',lgn[0])=0) and (pos('er2|',lgn[0])=0);
      toto:=toto and (pos('us|',lgn[0])=0) and (pos('us2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|eris');
         if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
            then mdl:='|5|'
            else mdl:='|7|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par en,in, is ou o.
         if ((mot[length(mot)]='r')or(mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='e')or(mot[length(mot)]='i')or(mot[length(mot)]='u'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure etis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_etis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('etis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('es|',lgn[0])=0) and (pos('es2|',lgn[0])=0);
//      toto:=toto and (pos('en2|',lgn[0])=0) and (pos('o2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|etis');
      if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
         then mdl:='|5|'
         else mdl:='|7|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par en,in, is ou o.
         if ((mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='e'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure alis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_alis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('alis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('al|',lgn[0])=0) and (pos('al2|',lgn[0])=0);
//      toto:=toto and (pos('en2|',lgn[0])=0) and (pos('o2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|alis');
      if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
         then mdl:='|5|'
         else mdl:='|8|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par en,in, is ou o.
         if ((mot[length(mot)]='l'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='a'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure aris;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_aris.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('aris',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('ar|',lgn[0])=0) and (pos('ar2|',lgn[0])=0);
//      toto:=toto and (pos('en2|',lgn[0])=0) and (pos('o2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|aris');
      if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
         then mdl:='|5|'
         else mdl:='|8|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par en,in, is ou o.
         if ((mot[length(mot)]='r')or(mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='a'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure otis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_otis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('otis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('os|',lgn[0])=0) and (pos('os2|',lgn[0])=0);
//      toto:=toto and (pos('en2|',lgn[0])=0) and (pos('o2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|otis');
      if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
         then mdl:='|5|'
         else mdl:='|7|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par en,in, is ou o.
         if ((mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='o'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure edis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_edis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('edis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if mot[1]='p' then mot:=copy(mot,2,length(mot));
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                        if genitif[1]='p' then genitif:=copy(genitif,2,length(genitif));
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         if mot[1]='p' then mot:=copy(mot,2,length(mot));
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
             end;
          end;
      if OK then begin
      toto:=(pos('es|',lgn[0])=0) and (pos('es2|',lgn[0])=0);
//      toto:=toto and (pos('en2|',lgn[0])=0) and (pos('o2|',lgn[0])=0);
      if toto then writeln(rejet,lgn[0],'|otis');
      if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
         then mdl:='|5|'
         else mdl:='|7|';
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par en,in, is ou o.
         if ((mot[length(mot)]='s'))
            then mot:=copy(mot,1,length(mot)-1);
         if ((mot[length(mot)]='e'))
            then mot:=copy(mot,1,length(mot)-1)
                                 else mot:=copy(mot,1,length(mot)-2);
         mot+=genitif;
         if mot[length(mot)-1]='i' then mot:=copy(mot,1,length(mot)-2)
                                   else mot:=copy(mot,1,length(mot)-3);
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure decl3_fin;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_decl3_fin.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_3e_decl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
//             if pos('otis',mot)=1 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      if genre='' then
                         genre:=copy(tab[3],pos(',',tab[3])+2,length(tab[3]));
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      else begin
                      mot1:=genitif;
                      toto:=toto and compatible(mot1,mot,genitif);
                      end;
                      end;
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     else begin
                         if pos(' ',tab[3])=0 then mot:=tab[3]
                         else mot:=copy(tab[3],1,pos(' ',tab[3])-1);
                         mot1:=genitif;
                         toto:=toto and compatible(mot1,mot,genitif);
                         end;
                     if genre='' then genre:=tab[4];
                     end;
 //            end;
          end;
      if OK then begin
      if ((genre='')or(pos('m.',genre)>0)or(pos('f.',genre)>0))
         then mdl:='|5|'
         else mdl:='|7|';
      explose(lgn[0],'|',tab);
      if copy(genitif,length(genitif)-1,2)='is' then
         mot:=par_position(recolle(tab[3],copy(genitif,1,length(genitif)-2)),false)
         else mot:=par_position(recolle(tab[3],genitif),false); // c'est le mot avec quantités.
         lgn[0]+=mdl+mot+'||'+genitif+', '+genre;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure etape8;

begin
   assign(rejet,'output/anomalies.txt');
   rewrite(rejet);
   numero:=96;
   onis;
   oris;
   atis;
   idis;
   icis;
   inis;
   adis;
   ontis;
   antis;
   entis;
   untis;
   acis;
   eris;
   etis;
   alis;
   otis;
   edis;
   aris;
   //enis, opis, elis et uris
   decl3_fin;
   CloseFile(rejet);
end;

procedure ns_ntis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_2e_cl.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_ns_ntis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      if copy(lgn[0],length(lgn[0])-1,2)='ns' then begin
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('tis',mot)>0 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      end
                      else if genitif='' then genitif:=tab[3];
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     end;
             end;
          end;
      if OK then begin
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par ns.
         mot[length(mot)]:='t';
         lgn[0]+='|14|'+mot+'||'+genitif;
      end;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure ax_acis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_ax_acis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      if lgn[0][length(lgn[0])]='x' then begin
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('acis',mot)>0 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      end
                      else if genitif='' then genitif:=tab[3];
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     end;
             end;
          end;
      if OK then begin
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par ax.
         mot[length(mot)]:='c';
         lgn[0]+='|14|'+mot+'||'+genitif;
      end;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure x_icis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_x_icis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      if lgn[0][length(lgn[0])]='x' then begin
      if copy(lgn[0],length(lgn[0])-2,3)='īx' then mdl:='|14|'
                                              else mdl:='|15|';
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('icis',mot)>0 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      end
                      else if genitif='' then genitif:=tab[3];
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     end;
             end;
          end;
      if OK then begin
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par ix ou ex.
         mot:=copy(mot,1,length(mot)-3);
         mot+=copy(genitif,length(genitif)-4,3); // Une fois, au moins, licis
         lgn[0]+=mdl+mot+'||'+genitif;
      end;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure s_idis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_s_idis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      if lgn[0][length(lgn[0])]='s' then begin
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('idis',mot)>0 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      end
                      else if genitif='' then genitif:=tab[3];
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     end;
             end;
          end;
      if OK then begin
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par is ou es.
         if ((mot[length(mot)-1]='i')or(mot[length(mot)-1]='e'))
            then mot:=copy(mot,1,length(mot)-2)
            else mot:=copy(mot,1,length(mot)-3);
         mot+=copy(genitif,length(genitif)-4,3); // Une fois, au moins, licis
         lgn[0]+='|15|'+mot+'||'+genitif;
      end;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure r_oris;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_r_oris.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      if lgn[0][length(lgn[0])]='r' then begin
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('oris',mot)>0 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      end
                      else if genitif='' then genitif:=tab[3];
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     end;
             end;
          end;
      if OK then begin
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par or ou ur.
         if ((mot[length(mot)-1]='o')or(mot[length(mot)-1]='u'))
            then mot:=copy(mot,1,length(mot)-2)
            else mot:=copy(mot,1,length(mot)-3);
         mot+=copy(genitif,length(genitif)-4,3); // Une fois, au moins, licis
         lgn[0]+='|15|'+mot+'||'+genitif;
      end;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure as_atis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_as_atis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      if lgn[0][length(lgn[0])]='s' then begin
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('atis',mot)>0 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      end
                      else if genitif='' then genitif:=tab[3];
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     end;
             end;
          end;
      if OK then begin
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par as.
         if ((mot[length(mot)-1]='a'))
            then mot:=copy(mot,1,length(mot)-2)
            else mot:=copy(mot,1,length(mot)-3);
         mot+=copy(genitif,length(genitif)-4,3); // Une fois, au moins, licis
         lgn[0]+='|15|'+mot+'||'+genitif;
      end;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure pes_pedis;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_es_edis.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
      explose(lgn[0],'|',tab);
      mot:=tab[1];
      if pos('=',mot)>0 then mot:=copy(mot,1,pos('=',mot)-1);
      if ord(mot[length(mot)])<64 then mot:=copy(mot,1,length(mot)-1);
      if copy(mot,length(mot)-2,3)='pes' then begin
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('edis',mot)>0 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      end
                      else if genitif='' then genitif:=tab[3];
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     end;
             end;
          end;
      if OK then begin
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par es.
         if ((mot[length(mot)-1]='e'))
            then mot:=copy(mot,1,length(mot)-2)
            else mot:=copy(mot,1,length(mot)-3);
         mot+='ĕd';   // pes -> pĕdis
         lgn[0]+='|15|'+mot+'||'+genitif;
      end;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure adj_er;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_adj_er.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=false;
      if copy(lgn[0],length(lgn[0])-2,3)='ĕr' then begin
      OK:=true;  // Je veux tous les adjectifs en er, qu'ils soient er, eris ou pas
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
             if pos('eris',mot)>0 then toto:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      end
                      else if genitif='' then genitif:=tab[3];
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     end;
          end;
      if OK then begin
         explose(lgn[0],'|',tab);
         mot:=tab[3]; // c'est le mot avec quantités. Se termine par er.
         mot:=copy(mot,1,length(mot)-3);
         if toto then begin  // eris
         if pos(',',genitif)>0 then genitif:=copy(genitif,1,length(genitif)-1);
         mot+=copy(genitif,length(genitif)-4,3);
         mdl:='|15|';
         end else begin
             mot1:=mot[length(mot)]+'r';
             mot:=rend_commune(copy(mot,1,length(mot)-1))+mot1;
             mdl:='|16|';
             end;
         lgn[0]+=mdl+mot+'||'+genitif;
      end;
      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure cl2_fin;

var mot: string;
    i, j: integer;
    tab: tableau;
    genitif, genre, mot1 : string;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_cl2_fin.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_2e_cl_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      genre:='';
      genitif:='';
      toto:=true;
//      if lgn[0][length(lgn[0])]='x' then begin
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             mot:=nettoie_gj(tab[3]);
//             if pos('acis',mot)>0 then begin
                OK:=true;
                if ((i=3)or(i=4)) then begin
                   if pos(',',tab[3])>0 then begin
                      mot:=copy(tab[3],1,pos(',',tab[3])-1);
                      if genitif='' then genitif:=mot
                      end
                      else if genitif='' then genitif:=tab[3];
                   end
                else begin
                     if genitif='' then begin
                        if pos(' ',tab[3])=0 then genitif:=tab[3]
                           else genitif:=copy(tab[3],1,pos(' ',tab[3])-1);
                           end
                     end;
//             end;
          end;
      if OK then begin
         explose(lgn[0],'|',tab);
         if pos(',',genitif)>0 then genitif:=copy(genitif,1,pos(',',genitif)-1);
         if copy(genitif,length(genitif)-1,2)='is' then
            mot:=par_position(recolle(tab[3],copy(genitif,1,length(genitif)-2)),false)
            else mot:=par_position(recolle(tab[3],genitif),false); // c'est le mot avec quantités.
         lgn[0]+='|15|'+mot+'||'+genitif;
      end;
//      end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure etape9;

begin
   numero:=96;
   ns_ntis;
   ax_acis;
   x_icis;
   s_idis;
   r_oris;
   as_atis;
   pes_pedis;
   adj_er;
   cl2_fin;
end;

procedure recolter;

var nom : string;
    cnt, i : integer;
    tab : tableau;

begin
   assign(fic_out,'fichiers_1/lem_ext.txt');
   rewrite(fic_out);
   assign(mots,'fichiers_1/lem_ext2.txt');
   rewrite(mots);
   assign(rejet,'fichiers_1/liste_lem6.txt');
   reset(rejet);
   repeat
      readln(rejet,nom);
      assign(fic_in,'fichiers_1/'+nom);
      reset(fic_in);
      repeat
         for i:=0 to 9 do readln(fic_in,lgn[i]);
         // J'ai lu un bloc
         explose(lgn[0],'|',tab);
         if ((tab[4]<>'')and(pos('+',lgn[0])=0)) then begin
         // Le champ 4 de la ligne 0 doit contenir le numéro de modèle.
         // S'il est vide, le bloc est ignoré : on peut ainsi traiter
         // le contenu de la poubelle au fur et à mesure.
         // De même s'il y a un + dans la ligne (collage non-vérifié).
         cnt:=0;
         for i:=1 to 6 do
             if ((length(lgn[i])>5){and(i<>5)}) then cnt+=1;
         if cnt>1 then for i:=0 to 9 do writeln(fic_out,lgn[i])
                  else for i:=0 to 9 do writeln(mots,lgn[i]);
         end;
      until eof(fic_in);
      CloseFile(fic_in);
   until eof(rejet);
   CloseFile(fic_out);
   CloseFile(mots);
   CloseFile(rejet);
end;

procedure finaliser;

var nom, clef : string;
    cnt, i : integer;
    tab : tableau;

begin
   assign(fic_in,'fichiers_1/lem_ext.txt');
   reset(fic_in);
   assign(fic_out,'fichiers_1/lem_ext_lat.csv');
   rewrite(fic_out);
   assign(mots,'fichiers_1/lem_ext_fr.csv');
   rewrite(mots);
   assign(rejet,'fichiers_1/lem_ext_uk.csv');
   rewrite(rejet);
   repeat
         for i:=0 to 9 do readln(fic_in,lgn[i]);
         // J'ai lu un bloc
         explose(lgn[0],'|',tab);
         if ((tab[2]<>'')and(tab[4]<>'')and(tab[0]<>'!')) then begin
            nom:=tab[2];
            clef:=nettoie_gj(tab[2]);
{            if pos('=',clef)>0 then clef:=copy(clef,1,pos('=',clef)-1);
            if clef<>lowercase(nettoie_gj(tab[2])) then clef+='§§§';   }
            if ord(nom[length(nom)])<64 then nom:=copy(nom,1,length(nom)-1);
            if ((tab[4]='4')and(copy(nom,length(nom)-1,2)='um')) then begin
               if copy(tab[3],length(tab[3])-2,3)='ŭm' then
                  tab[3]:=copy(tab[3],1,length(tab[3])-3)+'um';
            end;
            if nom=tab[3]
               then writeln(fic_out,clef,'|',tab[2],'|',tab[4],'|',tab[5],'|',tab[6],'|',tab[7],'|')
               else writeln(fic_out,clef,'|',tab[2],'=',tab[3],'|',tab[4],'|',tab[5],'|',tab[6],'|',tab[7],'|');
            explose(lgn[1],'|',tab); // le L&S
            if tab[6]='' then explose(lgn[6],'|',tab);  // Si le L&S est vide, j'essaie le Lw
            if tab[6]<>'' then writeln(rejet,clef,'|',tab[6]);
            explose(lgn[2],'|',tab); // Le Gaffiot
            if tab[6]='' then begin
               explose(lgn[3],'|',tab); // Le GJ
               if tab[4]<>'' then writeln(mots,clef,'|',tab[4]);
               end
            else writeln(mots,clef,'|',tab[6]);

         end;
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
   CloseFile(rejet);
end;

procedure finaliser2;

var nom, clef : string;
    cnt, i : integer;
    tab : tableau;

begin
   assign(fic_in,'fichiers_1/lem_ext2.txt');
   reset(fic_in);
   assign(fic_out,'fichiers_1/lem_ext2_lat.csv');
   rewrite(fic_out);
   assign(mots,'fichiers_1/lem_ext2_fr.csv');
   rewrite(mots);
   assign(rejet,'fichiers_1/lem_ext2_uk.csv');
   rewrite(rejet);
   repeat
         for i:=0 to 9 do readln(fic_in,lgn[i]);
         // J'ai lu un bloc
         explose(lgn[0],'|',tab);
         if ((tab[2]<>'')and(tab[4]<>'')and(tab[0]<>'!')) then begin
            nom:=tab[2];
            clef:=nettoie_gj(tab[2]);
{            if pos('=',clef)>0 then clef:=copy(clef,1,pos('=',clef)-1);
            if clef<>lowercase(nettoie_gj(tab[2])) then clef+='§§§';   }
            if ord(nom[length(nom)])<64 then nom:=copy(nom,1,length(nom)-1);
            if ((tab[4]='4')and(copy(nom,length(nom)-1,2)='um')) then begin
               if copy(tab[3],length(tab[3])-2,3)='ŭm' then
                  tab[3]:=copy(tab[3],1,length(tab[3])-3)+'um';
            end;
            if nom=tab[3]
               then writeln(fic_out,clef,'|',tab[2],'|',tab[4],'|',tab[5],'|',tab[6],'|',tab[7],'|')
               else writeln(fic_out,clef,'|',tab[2],'=',tab[3],'|',tab[4],'|',tab[5],'|',tab[6],'|',tab[7],'|');
            explose(lgn[1],'|',tab); // le L&S
            if tab[6]='' then explose(lgn[6],'|',tab);  // Si le L&S est vide, j'essaie le Lw
            if tab[6]<>'' then writeln(rejet,clef,'|',tab[6]);
            explose(lgn[2],'|',tab); // Le Gaffiot
            if tab[6]='' then begin
               explose(lgn[3],'|',tab); // Le GJ
               if tab[4]<>'' then writeln(mots,clef,'|',tab[4]);
               end
            else writeln(mots,clef,'|',tab[6]);

         end;
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
   CloseFile(rejet);
end;

procedure verb1;

var mot: string;
    i, j: integer;
    tab: tableau;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_verbes.txt');
   reset(fic_in);
   assign(fic_out,'output/lem6_vb1.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_verbes_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      explose(lgn[0],'|',tab);
      mot:=tab[1];
      if pos('=',mot)>0 then mot:=copy(mot,1,pos('=',mot)-1);
      if ord(mot[length(mot)])<64 then mot:=copy(mot,1,length(mot)-1);
      if mot[length(mot)]='o' then begin
         // c'est bon signe pour une forme active
         for i:=1 to 6 do
             if ((length(lgn[i])>5)and(i<>5)) then begin
                explose(lgn[i],'|',tab);
                OK:=OK or (pos('1',tab[3])>0) or (pos('āre',tab[3])>0);
                OK:=OK or (pos('Are',tab[3])>0) or (pos('are',tab[3])>0);
                OK:=OK or (pos('āvi',tab[3])>0);
                OK:=OK or ((pos('ātum',tab[3])>0)and(pos('ferre',tab[3])=0));
             end;
         end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb2;

var mot: string;
    i, j: integer;
    tab: tableau;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_verbes_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'output/lem6_vb2.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_verbes_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      explose(lgn[0],'|',tab);
      mot:=tab[1];
      if pos('=',mot)>0 then mot:=copy(mot,1,pos('=',mot)-1);
      if ord(mot[length(mot)])<64 then mot:=copy(mot,1,length(mot)-1);
      if copy(mot,length(mot)-1,2)='eo' then begin
         // 2e groupe nécessairement en eo.
         for i:=1 to 6 do
             if ((length(lgn[i])>5)and(i<>5)) then begin
                explose(lgn[i],'|',tab);
                OK:=OK or (pos('2',tab[3])>0) or (pos('ēre',tab[3])>0);
             end;
         end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb3;

var mot: string;
    i, j: integer;
    tab: tableau;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_verbes_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'output/lem6_vb3.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_verbes_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      explose(lgn[0],'|',tab);
      mot:=tab[1];
      if pos('=',mot)>0 then mot:=copy(mot,1,pos('=',mot)-1);
      if ord(mot[length(mot)])<64 then mot:=copy(mot,1,length(mot)-1);
      if mot[length(mot)]='o' then begin
         // c'est bon signe pour une forme active
         for i:=1 to 6 do
             if ((length(lgn[i])>5)and(i<>5)) then begin
                explose(lgn[i],'|',tab);
                OK:=OK or (pos('3',tab[3])>0) or (pos('ĕre',tab[3])>0);
                OK:=OK or (pos('ere',tab[3])>0);
             end;
         end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb4;

var mot: string;
    i, j: integer;
    tab: tableau;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_verbes_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'output/lem6_vb4.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_verbes_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      explose(lgn[0],'|',tab);
      mot:=tab[1];
      if pos('=',mot)>0 then mot:=copy(mot,1,pos('=',mot)-1);
      if ord(mot[length(mot)])<64 then mot:=copy(mot,1,length(mot)-1);
      if mot[length(mot)]='o' then begin
         // c'est bon signe pour une forme active
         for i:=1 to 6 do
             if ((length(lgn[i])>5)and(i<>5)) then begin
                explose(lgn[i],'|',tab);
                OK:=OK or (pos('4',tab[3])>0) or (pos('īre',tab[3])>0);
                OK:=OK or (pos('īrĕ',tab[3])>0) or (pos('Ire',tab[3])>0);
             end;
         end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb1d;

var mot, ind_m: string;
    i, j: integer;
    tab: tableau;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_verbes_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_vb1_dep.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_verbes_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      explose(lgn[0],'|',tab);
      mot:=tab[1];
      ind_m:='';
      if pos('=',mot)>0 then mot:=copy(mot,1,pos('=',mot)-1);
      if ord(mot[length(mot)])<64 then mot:=copy(mot,1,length(mot)-1);
      if copy(mot,length(mot)-1,2)='or' then begin
         // c'est bon signe pour une forme active
         for i:=1 to 6 do
             if ((length(lgn[i])>5)and(i<>5)) then begin
                explose(lgn[i],'|',tab);
                if ind_m='' then ind_m:=tab[3];
                OK:=OK or (pos('1',tab[3])>0) or (pos('āri',tab[3])>0);
                OK:=OK or (pos('ārī',tab[3])>0) or (pos('ātus sum',tab[3])>0);
                OK:=OK or (pos('Arī',tab[3])>0) or (pos('Atus sum',tab[3])>0);
             end;
         end;
      if OK then begin
                 lgn[0]+='|24|||'+ind_m;
                 // Après vérification, il n'y a pas de supin autre que atus.
                 intrans:=(pos(' n.',lgn[1])>0)or(pos('intr.',lgn[2])>0)or(pos('intr.',lgn[3])>0);
                 // Un des 3 premiers dicos le déclare intransitif.
                 trans:=(pos(' a.',lgn[1])>0)or(pos(' tr.',lgn[2])>0)or(pos('|tr.',lgn[2])>0);
                 trans:=trans or(pos(' tr.',lgn[3])>0)or(pos('|tr.',lgn[3])>0);
                 // Un des 3 premiers dicos le déclare transitif.
                 if (intrans and not trans) then lgn[0]+=', intr.';
                 for i:=0 to 9 do writeln(fic_out,lgn[i])
                 end
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb2d;

var mot, ind_m, us: string;
    i, j: integer;
    tab: tableau;
    OK, itus, autre_us: boolean;

begin
   assign(fic_in,'output/lem6_verbes_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_vb2_dep.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_verbes_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      itus:=false;
      autre_us:=false;
      ind_m:='';
      explose(lgn[0],'|',tab);
      mot:=tab[1];
      if pos('=',mot)>0 then mot:=copy(mot,1,pos('=',mot)-1);
      if ord(mot[length(mot)])<64 then mot:=copy(mot,1,length(mot)-1);
      if copy(mot,length(mot)-1,2)='or' then begin
         for i:=1 to 6 do
             if ((length(lgn[i])>5)and(i<>5)) then begin
                explose(lgn[i],'|',tab);
                OK:=OK or (pos('2',tab[3])>0) or (pos('ēri',tab[3])>0);
                OK:=OK or (pos('Erī',tab[3])>0) or (pos('ērī',tab[3])>0);
                mot:=lowercase(nettoie_gj(tab[3]));
                if pos('itus',mot)>0 then itus:=true
                   else if pos('us',mot)>0 then begin
                   autre_us:=true;
                   if ind_m='' then ind_m:=tab[3];
                   end;
             end;
         end;
      if OK then begin
                 explose(lgn[0],'|',tab);
                 mot:=tab[3];
                 if ind_m='' then ind_m:='ēri';
                 if itus then begin
                              mot:=copy(mot,1,length(mot)-5)+'ĭt';
                              ind_m:='ēri, ĭtus sum';
                              end
                         else if autre_us then begin
                             mot:=copy(mot,1,length(mot)-5);
                             us:=copy(ind_m,1,pos('us',ind_m)-1);
                             while pos(' ',us)>0 do us:=copy(us,pos(' ',us)+1,length(us));
                             mot:=par_position(recolle(mot,us),false);
                             end
                        else mot:='';
                 lgn[0]+='|25||'+mot+'|'+ind_m;
                 intrans:=(pos(' n.',lgn[1])>0)or(pos('intr.',lgn[2])>0)or(pos('intr.',lgn[3])>0);
                 // Un des 3 premiers dicos le déclare intransitif.
                 trans:=(pos(' a.',lgn[1])>0)or(pos(' tr.',lgn[2])>0)or(pos('|tr.',lgn[2])>0);
                 trans:=trans or(pos(' tr.',lgn[3])>0)or(pos('|tr.',lgn[3])>0);
                 // Un des 3 premiers dicos le déclare transitif.
                 if (intrans and not trans) then lgn[0]+=', intr.';
                 for i:=0 to 9 do writeln(fic_out,lgn[i])
                 end
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb3d;

var mot: string;
    i, j: integer;
    tab: tableau;
    OK, toto: boolean;

begin
   assign(fic_in,'output/lem6_verbes_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'output/lem6_vb3_dep.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_verbes_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      explose(lgn[0],'|',tab);
      mot:=tab[1];
      if pos('=',mot)>0 then mot:=copy(mot,1,pos('=',mot)-1);
      if ord(mot[length(mot)])<64 then mot:=copy(mot,1,length(mot)-1);
      if copy(mot,length(mot)-1,2)='or' then begin
         for i:=1 to 6 do
             if ((length(lgn[i])>5)and(i<>5)) then begin
                explose(lgn[i],'|',tab);
                OK:=OK or (pos('3',tab[3])>0) or (pos('i',tab[3])>0);
             end;
         end;
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb4d;

var mot, ind_m : string;
    i, j: integer;
    tab: tableau;
    OK, itus, mensus: boolean;

begin
   assign(fic_in,'output/lem6_verbes_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_vb4_dep.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_verbes_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      itus:=false;
      mensus:=false;
      explose(lgn[0],'|',tab);
      mot:=tab[1];
      if pos('=',mot)>0 then mot:=copy(mot,1,pos('=',mot)-1);
      if ord(mot[length(mot)])<64 then mot:=copy(mot,1,length(mot)-1);
      if copy(mot,length(mot)-1,2)='or' then begin
         for i:=1 to 6 do
             if ((length(lgn[i])>5)and(i<>5)) then begin
                explose(lgn[i],'|',tab);
                OK:=OK or (pos('4',tab[3])>0) or (pos('īri',tab[3])>0);
                OK:=OK or (pos('Irī',tab[3])>0) or (pos('īrī',tab[3])>0);
                // Si j'ai bien vu, ils sont en iri seul
                // ou avec un supin en itus ou mensus
                mot:=lowercase(nettoie_gj(tab[3]));
                if pos('itus',mot)>0 then itus:=true;
                if pos('mensus',mot)>0 then mensus:=true;
             end;
         end;
      if OK then begin
                 explose(lgn[0],'|',tab);
                 mot:=tab[3];
                 ind_m:='īri';
                 if itus then begin
                              mot:=copy(mot,1,length(mot)-5)+'īt';
                              ind_m+=', ītus sum';
                              end
                    else if mensus then begin
                                        mot:=copy(mot,1,length(mot)-8)+'ēns';
                                        ind_m+=', mensus sum';
                                        end
                                   else mot:='';
                 lgn[0]+='|28||'+mot+'|'+ind_m;
                 intrans:=(pos(' n.',lgn[1])>0)or(pos('intr.',lgn[2])>0)or(pos('intr.',lgn[3])>0);
                 // Un des 3 premiers dicos le déclare intransitif.
                 trans:=(pos(' a.',lgn[1])>0)or(pos(' tr.',lgn[2])>0)or(pos('|tr.',lgn[2])>0);
                 trans:=trans or(pos(' tr.',lgn[3])>0)or(pos('|tr.',lgn[3])>0);
                 // Un des 3 premiers dicos le déclare transitif.
                 if (intrans and not trans) then lgn[0]+=', intr.';
                 for i:=0 to 9 do writeln(fic_out,lgn[i])
                 end
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb_fio;

var mot, ind_m : string;
    i, j: integer;
    tab: tableau;
    OK, itus, mensus: boolean;

begin
   assign(fic_in,'output/lem6_verbes_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_vb_fio.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_verbes_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      itus:=false;
      mensus:=false;
      explose(lgn[0],'|',tab);
      mot:=tab[1];
      if pos('=',mot)>0 then mot:=copy(mot,1,pos('=',mot)-1);
      if ord(mot[length(mot)])<64 then mot:=copy(mot,1,length(mot)-1);
      if copy(mot,length(mot)-2,3)='fio' then begin
                 mot:=copy(tab[3],1,length(tab[3])-3);
                 if mot[length(mot)]<>'f' then mot:=copy(mot,1,length(mot)-1);
                 lgn[0]+='|35||'+mot+'āct|fĭĕri, factus sum (passif de ';
                 lgn[0]+=nettoie_gj(mot)+'acio)';
                 for i:=0 to 9 do writeln(fic_out,lgn[i])
                 end
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb_fero;

var mot, ind_m : string;
    i, j: integer;
    tab: tableau;
    OK, itus, mensus: boolean;

begin
   assign(fic_in,'output/lem6_verbes_'+chr(numero)+'.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_vb_fero.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'output/lem6_verbes_'+chr(numero)+'.txt');
   rewrite(mots);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      itus:=false;
      mensus:=false;
      ind_m:='';
      explose(lgn[0],'|',tab);
      mot:=tab[1];
      if pos('=',mot)>0 then mot:=copy(mot,1,pos('=',mot)-1);
      if ord(mot[length(mot)])<64 then mot:=copy(mot,1,length(mot)-1);
      if copy(mot,length(mot)-3,4)='fero' then begin
         mot:=copy(tab[3],1,length(tab[3])-5);
         for i:=1 to 6 do
             if ((length(lgn[i])>5)and(i<>5)and(ind_m='')) then begin
                explose(lgn[i],'|',tab);
                ind_m:=tab[3];
             end;
                 lgn[0]+='|33|'+mot+'tŭl|'+mot+'lāt|'+ind_m;
                 for i:=0 to 9 do writeln(fic_out,lgn[i])
                 end
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb3d2;

var mot, ind_m, us : string;
    i, j: integer;
    tab: tableau;
    OK, itus, mensus: boolean;

begin
   assign(fic_in,'output/lem6_vb3_dep.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_vb3_dep1.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'fichiers/lem6_vb3_dep2.txt');
   rewrite(mots);
   // J'ai un verbe déponent du 3e groupe : 27 si -ior, 26 sinon.
   // S'il y a une indication en -us, je prépare le collage.
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      ind_m:='';
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             if ind_m='' then ind_m:=tab[3];
             if pos('us',tab[3])>0 then begin
                if not OK then ind_m:=tab[3];
                OK:=true;
                end;
             end;
      explose(lgn[0],'|',tab);
      mot:=tab[1];
      if pos('=',mot)>0 then mot:=copy(mot,1,pos('=',mot)-1);
      if ord(mot[length(mot)])<64 then mot:=copy(mot,1,length(mot)-1);
      if mot[length(mot)-2]='i' then mdl:='|27||'
                                else mdl:='|26||';
      mot:=tab[3];
      if OK then begin
                 us:=copy(ind_m,1,pos('us',ind_m)-1);
                 while pos(' ',us)>0 do us:=copy(us,pos(' ',us)+1,length(us));
                 lgn[0]+=mdl+par_position(recolle(mot,us),false)+'|'+ind_m
                 end
            else lgn[0]+=mdl+'|'+ind_m; // pas de supin
      intrans:=(pos(' n.',lgn[1])>0)or(pos('intr.',lgn[2])>0)or(pos('intr.',lgn[3])>0);
      // Un des 3 premiers dicos le déclare intransitif.
      trans:=(pos(' a.',lgn[1])>0)or(pos(' tr.',lgn[2])>0)or(pos('|tr.',lgn[2])>0);
      trans:=trans or(pos(' tr.',lgn[3])>0)or(pos('|tr.',lgn[3])>0);
      // Un des 3 premiers dicos le déclare transitif.
      if (intrans and not trans) then lgn[0]+=', intr.';
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb1_2;

var mot, ind_m, supin, parf : string;
    i, j: integer;
    tab: tableau;
    OK, itus, mensus: boolean;

begin
   assign(fic_in,'output/lem6_vb1.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_vb1_1.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'fichiers/lem6_vb1_2.txt');
   rewrite(mots);
   // J'ai un verbe  du 1e groupe : 17.
   // S'il y a une indication en -um autre que atum, je prépare le collage.
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      ind_m:='';
      supin:='';
      parf:='';
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             if ind_m='' then ind_m:=tab[3];
             mot:=lowercase(nettoie_gj(tab[3]));
             if ((pos('um',mot)>0)and(pos('atum',mot)=0)) then begin
                if supin='' then begin
                supin:=copy(tab[3],1,pos('um',tab[3])-1);
                while pos(' ',supin)>0 do supin:=copy(supin,pos(' ',supin)+1,length(supin));
                end;
                OK:=true;
                end;
             if ((pos('i',mot)>0)and(pos('avi',mot)=0)) then begin
                if parf='' then begin
                if pos('i',tab[3])>0 then parf:=copy(tab[3],1,pos('i',tab[3])-1)
                else if pos('ī',tab[3])>0 then parf:=copy(tab[3],1,pos('ī',tab[3])-1)
                ;
                while pos(' ',parf)>0 do parf:=copy(parf,pos(' ',parf)+1,length(parf));
                end;
                OK:=true;
                end;
             end;
      explose(lgn[0],'|',tab);
      mot:=tab[3];
      if mot[length(mot)]='o' then mot:=copy(mot,1,length(mot)-1)
                              else mot:=copy(mot,1,length(mot)-2);
      if parf<>'' then begin
                  if parf[length(parf)]='u' then begin
                     if length(parf)=1 then parf:='ŭ'
                        else parf:=copy(parf,1,length(parf)-1)+'ŭ';
                     end;
                 lgn[0]+='|17|'+par_position(recolle(mot,parf),false)+'|';
                 end
            else lgn[0]+='|17||'; // pas de parfait
      if supin<>'' then begin
                 lgn[0]+=par_position(recolle(mot,supin),false)+'|'+ind_m;
                 end
            else lgn[0]+='|'+ind_m; // pas de supin
      intrans:=(pos(' n.',lgn[1])>0)or(pos('intr.',lgn[2])>0)or(pos('intr.',lgn[3])>0);
      // Un des 3 premiers dicos le déclare intransitif.
      trans:=(pos(' a.',lgn[1])>0)or(pos(' tr.',lgn[2])>0)or(pos('|tr.',lgn[2])>0);
      trans:=trans or(pos(' tr.',lgn[3])>0)or(pos('|tr.',lgn[3])>0);
      // Un des 3 premiers dicos le déclare transitif.
      if (intrans and not trans) then lgn[0]+=', intr.';
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb2_2;

var mot, ind_m, supin, parf : string;
    i, j: integer;
    tab: tableau;
    OK, itus, mensus: boolean;

begin
   assign(fic_in,'output/lem6_vb2.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_vb2_1.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'fichiers/lem6_vb2_2.txt');
   rewrite(mots);
   // J'ai un verbe  du 2e groupe : 18.
   // S'il y a une indication en -um autre que atum, je prépare le collage.
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      ind_m:='';
      supin:='';
      parf:='';
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             if ind_m='' then ind_m:=tab[3];
             mot:=lowercase(nettoie_gj(tab[3]));
             if pos('um',mot)>0 then begin
                if supin='' then begin
                supin:=copy(tab[3],1,pos('um',tab[3])-1);
                while pos(' ',supin)>0 do supin:=copy(supin,pos(' ',supin)+1,length(supin));
                end;
                OK:=true;
                end;
             if ((pos('i',mot)>0)and(pos('avi',mot)=0)) then begin
                if parf='' then begin
                if pos('i',tab[3])>0 then parf:=copy(tab[3],1,pos('i',tab[3])-1)
                else if pos('ī',tab[3])>0 then parf:=copy(tab[3],1,pos('ī',tab[3])-1)
                ;
                while pos(' ',parf)>0 do parf:=copy(parf,pos(' ',parf)+1,length(parf));
                end;
                OK:=true;
                end;
             end;
      explose(lgn[0],'|',tab);
      mot:=tab[3];
      if mot[length(mot)]='o' then mot:=copy(mot,1,length(mot)-3)
                              else mot:=copy(mot,1,length(mot)-4); // eo
      if parf<>'' then begin
                  if parf[length(parf)]='u' then begin
                     if length(parf)=1 then parf:='ŭ'
                           else parf:=copy(parf,1,length(parf)-1)+'ŭ';
                     end;
                 lgn[0]+='|18|'+par_position(recolle(mot,parf),false)+'|';
                 end
            else lgn[0]+='|18||'; // pas de parfait
      if supin<>'' then begin
                 lgn[0]+=par_position(recolle(mot,supin),false)+'|'+ind_m;
                 end
            else lgn[0]+='|'+ind_m; // pas de supin
      intrans:=(pos(' n.',lgn[1])>0)or(pos('intr.',lgn[2])>0)or(pos('intr.',lgn[3])>0);
      // Un des 3 premiers dicos le déclare intransitif.
      trans:=(pos(' a.',lgn[1])>0)or(pos(' tr.',lgn[2])>0)or(pos('|tr.',lgn[2])>0);
      trans:=trans or(pos(' tr.',lgn[3])>0)or(pos('|tr.',lgn[3])>0);
      // Un des 3 premiers dicos le déclare transitif.
      if (intrans and not trans) then lgn[0]+=', intr.';
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb3_2;

var mot, ind_m, supin, parf : string;
    i, j: integer;
    tab: tableau;
    OK, itus, mensus: boolean;

begin
   assign(fic_in,'output/lem6_vb3.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_vb3_1.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'fichiers/lem6_vb3_2.txt');
   rewrite(mots);
   // J'ai un verbe  du 3e groupe : 19 ou 20 (en -io).
   // S'il y a une indication en -um, je prépare le collage.
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=false;
      ind_m:='';
      supin:='';
      parf:='';
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             if ind_m='' then ind_m:=tab[3];
             mot:=lowercase(nettoie_gj(tab[3]));
             if pos('um',mot)>0 then begin
                if supin='' then begin
                supin:=copy(tab[3],1,pos('um',tab[3])-1);
                while pos(' ',supin)>0 do supin:=copy(supin,pos(' ',supin)+1,length(supin));
                end;
                OK:=true;
                end;
             if ((pos('i',mot)>0)and(pos('avi',mot)=0)) then begin
                if parf='' then begin
                if pos('i',tab[3])>0 then parf:=copy(tab[3],1,pos('i',tab[3])-1)
                else if pos('ī',tab[3])>0 then parf:=copy(tab[3],1,pos('ī',tab[3])-1)
                ;
                while pos(' ',parf)>0 do parf:=copy(parf,pos(' ',parf)+1,length(parf));
                end;
                OK:=true;
                end;
             end;
      explose(lgn[0],'|',tab);
      mot:=tab[3];
      if mot[length(mot)]='o' then mot:=copy(mot,1,length(mot)-1)
                              else mot:=copy(mot,1,length(mot)-2); // o long
      if copy(mot,length(mot)-1,2)='ĭ' then mdl:='|20|'
                                      else mdl:='|19|';
      if parf<>'' then begin
                  if parf[length(parf)]='u' then begin
                     if length(parf)=1 then parf:='ŭ'
                           else parf:=copy(parf,1,length(parf)-1)+'ŭ';
                     end;
                 lgn[0]+=mdl+par_position(recolle(mot,parf),false)+'|';
                 end
            else lgn[0]+=mdl+'|'; // pas de parfait
      if supin<>'' then begin
                 lgn[0]+=par_position(recolle(mot,supin),false)+'|'+ind_m;
                 end
            else lgn[0]+='|'+ind_m; // pas de supin
      intrans:=(pos(' n.',lgn[1])>0)or(pos('intr.',lgn[2])>0)or(pos('intr.',lgn[3])>0);
      // Un des 3 premiers dicos le déclare intransitif.
      trans:=(pos(' a.',lgn[1])>0)or(pos(' tr.',lgn[2])>0)or(pos('|tr.',lgn[2])>0);
      trans:=trans or(pos(' tr.',lgn[3])>0)or(pos('|tr.',lgn[3])>0);
      // Un des 3 premiers dicos le déclare transitif.
      if (intrans and not trans) then lgn[0]+=', intr.';
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure verb4_2;

var mot, ind_m, supin, parf : string;
    i, j: integer;
    tab: tableau;
    OK, itus, mensus: boolean;

begin
   assign(fic_in,'output/lem6_vb4.txt');
   reset(fic_in);
   assign(fic_out,'fichiers/lem6_vb4_1.txt');
   rewrite(fic_out);
   numero+=1;
   assign(mots,'fichiers/lem6_vb4_2.txt');
   rewrite(mots);
   // J'ai un verbe  du 4e groupe : 21 (en -io).
   // S'il y a une indication en -um, je prépare le collage.
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      OK:=true;
      ind_m:='';
      supin:='';
      parf:='';
      for i:=1 to 6 do
          if ((length(lgn[i])>5)and(i<>5)) then begin
             explose(lgn[i],'|',tab);
             if ind_m='' then ind_m:=tab[3];
             mot:=lowercase(nettoie_gj(tab[3]));
             if pos('um',mot)>0 then begin
                if supin='' then begin
                supin:=copy(tab[3],1,pos('um',tab[3])-1);
                while pos(' ',supin)>0 do supin:=copy(supin,pos(' ',supin)+1,length(supin));
                end;
                OK:=true;
                end;
             if ((pos('i',mot)>0)and(pos('avi',mot)=0)) then begin
                if parf='' then begin
                if pos('i',tab[3])>0 then parf:=copy(tab[3],1,pos('i',tab[3])-1)
                else if pos('ī',tab[3])>0 then parf:=copy(tab[3],1,pos('ī',tab[3])-1)
                ;
                while pos(' ',parf)>0 do parf:=copy(parf,pos(' ',parf)+1,length(parf));
                end;
                OK:=true;
                end;
             end;
      explose(lgn[0],'|',tab);
      mot:=tab[3];
      if mot[length(mot)]='o' then mot:=copy(mot,1,length(mot)-1)
                              else mot:=copy(mot,1,length(mot)-2); // o long
      if copy(mot,length(mot)-1,2)='ĭ' then mdl:='|21|'
                                      else mdl:='|23|'; // eo
      mot:=copy(mot,1,length(mot)-2); // enlève i ou e brefs
      if parf<>'' then begin
                  if parf[length(parf)]='u' then begin
                     if length(parf)=1 then parf:='ŭ'
                           else parf:=copy(parf,1,length(parf)-1)+'ŭ';
                     end;
                 lgn[0]+=mdl+par_position(recolle(mot,parf),false)+'|';
                 end
            else lgn[0]+=mdl+'|'; // pas de parfait
      if supin<>'' then begin
                 lgn[0]+=par_position(recolle(mot,supin),false)+'|'+ind_m;
                 end
            else lgn[0]+='|'+ind_m; // pas de supin
      intrans:=(pos(' n.',lgn[1])>0)or(pos('intr.',lgn[2])>0)or(pos('intr.',lgn[3])>0);
      // Un des 3 premiers dicos le déclare intransitif.
      trans:=(pos(' a.',lgn[1])>0)or(pos(' tr.',lgn[2])>0)or(pos('|tr.',lgn[2])>0);
      trans:=trans or(pos(' tr.',lgn[3])>0)or(pos('|tr.',lgn[3])>0);
      // Un des 3 premiers dicos le déclare transitif.
      if (intrans and not trans) then lgn[0]+=', intr.';
      if OK then for i:=0 to 9 do writeln(fic_out,lgn[i])
            else for i:=0 to 9 do writeln(mots,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
   CloseFile(mots);
end;

procedure etape10;

begin
   numero:=96;
   verb1;
   verb2;
   verb3;
   verb4;
   verb1d;
   verb2d;
   verb4d;
   verb3d;
   verb_fio;
   verb_fero;
   verb1_2; // Je prépare le collage du radical
   verb3d2; // Je prépare le collage du radical
   verb2_2; // Je prépare le collage du radical
   verb3_2; // Je prépare le collage du radical
   verb4_2; // Je prépare le collage du radical
end;

procedure controler;

var ww, mot : string;
    tab : tableau;
    erreur : boolean;

begin
   assign(fic_in,'output/lem_ext.txt');
   reset(fic_in);
   assign(fic_out,'output/lem_erreurs.txt');
   rewrite(fic_out);
   repeat
      for i:=0 to 9 do readln(fic_in,lgn[i]);
      // J'ai lu un bloc
      erreur:=false;
      explose(lgn[0],'|',tab);
      if ((tab[5]<>'')and(pos('+',tab[5])=0)and(pos(',',lgn[9])>0)) then begin
      // J'ai un radical (parfait ou génitif) et WW me dit quelque chose
      ww:=copy(lgn[9],pos(',',lgn[9])+2,length(lgn[9]));
      mot:=nettoie_gj(tab[5])+'i';
      if ((ww[length(ww)]='i')or(copy(ww,length(ww)-1,2)='is')) then
      // c'est aussi un parfait ou un génitif
         erreur:=pos(mot,ww)<>1;
      end;
      erreur:=erreur or (pos(' ',tab[5])>0) or (pos(' ',tab[6])>0);
      if erreur then for i:=0 to 9 do writeln(fic_out,lgn[i]);
   until eof(fic_in);
   CloseFile(fic_in);
   CloseFile(fic_out);
end;

initialization

//     etape1;
              {Sépare les lemmes en 3 catégories :
              - les lemmes isolés (qui ne sont que dans un seul dico)
              - les lemmes simples (qui sont dans au moins 2 dicos)
              - les lemmes multiples (quel que soit le nb de dicos)
              Un traitement spécial est réservé aux 2 dicos Semi-Ramistes}
//     etape2;
              {Cherche les j devenus i, dans petit Lewis et le Georges.
              Ces mots sont dans lem_isol1.csv quand ils sont simples et
              dans lem_SR1.csv quand ils sont multiples et Semi_Ramistes.
              Il faut les remettre au bon endroit dans lem_ok ou lem_mult.
              Les fichiers en sortie sont lem_ok2a.csv, lem_mult2a.csv et lem_isol2b.csv}
//     liste_lemmes;
  //   Separe_Collatinus;
              {Je fais la liste des seuls lemmes trouvés dans les trois fichiers.}
//     liste_assimil;
//     separe_doublons;
//     sep_db;
//     sep_parfaits;
//     moissonne;
//     liste_lemmes2;
//     etablir_Q;
//     etape7;
//     typ_decl_3;
//     typ_cl_2;
  //   etape8;  // Les noms de la 3e déclinaison
    // etape9;  // Les adjectif de la 2e classe
//     etape10; // Les verbes
     recolter;
//     controler;
     finaliser;
     finaliser2;
//     compte_lettres;
     //       compare;
//     etape3bis; // le tri des homonymes a été fait dans un programme différent
     // Il faut vérifier le numéro des homonymes déjà dans le lexique de Collatinus
//     etape3;
//     typologie;
//     typologie_Ge;
//     norm_LS;
//     norm_Lewis;
//     norm_GJ;
//     test_ordre('Gaffiot_GG_fini');
//     test_pp;
//     verif_Q2;
//     adj_subst;
end.

