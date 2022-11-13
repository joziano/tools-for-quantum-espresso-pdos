#!/bin/bash
##########################################################################
# pdos-sum.sh is an auxiliary tool for sumpdos.x of the Quantum Espresso #
# package. It organizes the PDOS sum process. This version organizes     #
# the sum processes by atoms and orbitals, excluding the case where the  #
# spin-orbit interaction is considered.                                  #
# Copyright (C) <2021>  <J.R.M. Monteiro and Henrique Pecinatto>         #
# e-mail: joziano@protonmail.com | pecinatto@ufam.edu.br                 #
# Version 1, Dec 21, 2021 (No Spin Orbit version)                        #
##########################################################################
# LICENSE INFORMATION                                                    #
#                                                                        #
# This program is free software: you can redistribute it and/or modify   #
# it under the terms of the GNU General Public License as published by   #
# the Free Software Foundation, either version 3 of the License, or      #
# (at your option) any later version.                                    #
#                                                                        #
# This program is distributed in the hope that it will be useful,        #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# GNU General Public License for more details.                           #
#                                                                        #
# You should have received a copy of the GNU General Public License      #
# along with this program.  If not, see <https://www.gnu.org/licenses/>5.#
##########################################################################

##########################################################################
# INFORMATION ############################################################
# This program is run in terminal as: bash pdos-sum.sh                   #
##########################################################################


# Test the existence of sumpdos.x program and capture the path           

if test $(locate bin/sumpdos.x 2>/dev/null | wc -l) -eq 0                
then                                                                     
  echo "..Error. sumpdos.x not found"                                     
  echo "..Please, install Quantum Espresso package"                       
  exit                                                                    
fi                                                                       

if test $(locate bin/sumpdos.x 2>/dev/null | wc -l) -eq 1                
then                                                                     
  echo "..sumpdos.x found"                                                
  echo "..using the path $(locate bin/sumpdos.x)"                         
  MYCOMMAND="$(locate bin/sumpdos.x)"                                     
fi                                                                       

if test $(locate bin/sumpdos.x 2>/dev/null | wc -l) -gt 1                
then                                                                     
  echo "..multiple versions of sumpdos.x were found."                     
  echo "..using the path $(locate bin/sumpdos.x | tail -1)"               
  MYCOMMAND="$(locate bin/sumpdos.x | tail -1)"                           
fi                                                                       

# Test the existence of scf output file in the current directory and     
# capture the elements and number of elements                            

if test $(ls *.scf.out 2>/dev/null | wc -l) -gt 0                        
then                                                                     
  grep -w "number of atomic types" $(ls *.scf.out) >> ntyp.txt            
  sed -e "s/number of atomic types    =//g" -i ntyp.txt                   
  sed -e " s/ //g" -i ntyp.txt                                            
  NTYP=($(awk '{print $1}' ntyp.txt)) && rm ntyp.txt                      
  echo "$(grep -A "$NTYP" "atomic species   v" $(ls *.scf.out))" >> e.txt 
  sed -i '1d' e.txt                                                       
else                                                                     
 echo "..Error. The scf output is not present in the current directory." 
 echo "..Please, bring the scf output file into this directory."         
 exit                                                                    
fi                                                                       

awk '{print $1}' e.txt > elements.txt                                    
ELEMENTS=($(awk '{print $1}' e.txt)) && NE=$(($NTYP-1)) && rm e.txt      

# PDOS original data backup                                              

echo  ""                                                                 
echo "..Creating data backups"                                           
FOLDERJOB=${PWD##*/}                                                     
cd ..                                                                    
cp -r $FOLDERJOB ./original_data                                         
mv original_data ./$FOLDERJOB                                            
cd $FOLDERJOB                                                            
echo "..done"                                                            
echo  ""                                                                 

# PDOS Funcion to perform PDOS sum per atom and atomic orbitals

PDOS() {                                                                 
 mkdir $ELEMENT                                                          
 for a in *"($ELEMENT)"*; do mv $a ./$ELEMENT; done                      
 cp -r $ELEMENT ./orbitals                                               
                                                                         
 LAYERS=(s p d f)                                                        
                                                                         
 cd $ELEMENT                                                             
                                                                         
  for k in $(seq 0 1 3)                                                  
  do                                                                     
   if test $(ls ./*"(${LAYERS[k]})"* 2>/dev/null | wc -l) -gt 0          
   then mkdir ../orbitals/$ELEMENT/${LAYERS[k]}; fi                      
  done                                                                   
                                                                         
 $MYCOMMAND *"($ELEMENT)"* > ${ELEMENT}.dat                              
 cp ${ELEMENT}.dat ../orbitals/plot; cd ..                               
                                                                         
 cd orbitals/$ELEMENT                                                    
                                                                         
  for k in $(seq 0 1 3)                                                  
  do                                                                     
    if test $(ls ./*"(${LAYERS[k]})"* 2>/dev/null | wc -l) -gt 0          
    then                                                                  
      for a in *"(${LAYERS[k]})"*; do mv $a ./${LAYERS[k]}; done           
      cd ${LAYERS[k]}                                                      
      $MYCOMMAND *"($ELEMENT)"* > ${ELEMENT}_orb_${LAYERS[k]}.dat          
      cp ${ELEMENT}_orb_${LAYERS[k]}.dat ../                               
      cd ..                                                                
      mv ${ELEMENT}_orb_${LAYERS[k]}.dat ../plot                           
    fi                                                                    
  done                                                                   
                                                                         
  cd .. && mv ${ELEMENT} ./atoms && cd .. && mv ${ELEMENT} ./atoms       
}                                                                        

echo "..Start sumpdos.x from Quantum Espresso:"                          
echo ""                                                                  

# Perform the sum per orbitals (all elements contribuition) 

mkdir orbitals atoms orbitals/plot orbitals/atoms                        
                                                                         
LAYERS=(s p d f)                                                         
                                                                         
  for k in $(seq 0 1 3)                                                  
  do                                                                     
   if test $(ls ./*"(${LAYERS[k]})"* 2>/dev/null | wc -l) -gt 0          
   then                                                                  
      mkdir orbitals/${LAYERS[k]}                                          
      $MYCOMMAND *"(${LAYERS[k]})"* > ${LAYERS[k]}_orb.dat                 
      cp ${LAYERS[k]}_orb.dat ./orbitals/plot                              
      mv ${LAYERS[k]}_orb.dat ./orbitals/${LAYERS[k]}; 
    fi                  
  done                                                                   

# Run the PDOS function 

for j in $(seq 0 1 $NE)                                                  
do                                                                       
  ELEMENT=${ELEMENTS[j]}                                                  
  PDOS                                                                    
done                                                                     

echo ""                                                                  
echo "..End sumpdos.x from Quantum Espresso"                             
echo ""                                                                  

# Data organization

cd orbitals && mv plot ../pdos-data && cd ..                             
rm -r atoms orbitals                                                     
mv elements.txt ./pdos-data                                              
rm ./* 2>/dev/null
cd original_data && cp $(ls *pdos_tot) ../pdos-data && cd ..                                                        

echo "..pdos-sum.sh | tool to sumpdos.x | no spin orbit version"         
echo "..Source code provided by J.R.M. Monteiro and Henrique Pecinatto"  
echo "..e-mail: joziano@protonmail.com | pecinatto@ufam.edu.br"          
echo "..Version 1, Dec 21, 2021"                                         
form_a="+%d/%m/%y" && form_b="+%Hh:%Mmin"                                
echo ""                                                                  

echo "..Program pdos-sum.sh was executed successfully"                   
echo "..JOB DONE in $(date $form_a) at $(date $form_b) by user $USER"    

exit 0
