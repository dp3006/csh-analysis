#!/bin/tcsh

echo "##################################################################################"
echo "|                         Gridmaker has started running                          |"
echo "##################################################################################"



set Full = `more +11 config.txt | head -1 | awk '{print $1}'`
set counter = 1
set dx = `echo "scale=10; 0.5" | bc -l`
set min_x = `awk '{print $1}'  gmtfile_Sep.txt `
set max_x = `awk '{print $2}'  gmtfile_Sep.txt `
set min_y = `awk '{print $3}'  gmtfile_Sep.txt `
set max_y = `awk '{print $4}'  gmtfile_Sep.txt `
set map_area = `echo "scale=10; 1.89881265089" | bc -l`

set Category_number = `more +12 config.txt | head -1 | awk '{print $1}'`
echo "Number of Categories chosen = " $Category_number
echo "These are the weights used "
echo "" > weights.txt
if ( $Category_number != 1) then
    more +13 config.txt | head -`expr $Category_number ` | awk '{print $2}' > weights.txt 
endif
head weights.txt
# set limitsornot = `more +13  config.txt | head -1 | awk '{print $1}'`

gmtinfo -C $Full > gmtfile_Full.txt

more +13 config.txt | head -`expr $Category_number - 1` | awk '{print ($1)/1000}'  > limits.txt 

awk '{print $5}'  gmtfile_Full.txt  > min_R.txt
awk '{print ($6)+0.000000001}'  gmtfile_Full.txt  > max_R.txt #ask phil
cat  min_R.txt limits.txt max_R.txt > minmax.txt # this has to be divided by the map area.
echo "this are the limits in kilometers"
head minmax.txt
#foreach j ("` cat minmax.txt`") # make from config file | piped for number of rows wanted, remove pipe later


if ( $Category_number > 1 ) then
    set all_sum = 0
    foreach k ("`cat weights.txt`") 
        set all_sum = `echo "scale=10; $all_sum + $k " | bc -l`
    end
    echo "The sum of all weights = "$all_sum " ,the program will continue"
    if ( $all_sum != 100) then
        echo "Sum of weights is not equal to a 100 percent"
        exit 1
    endif
endif
# foreach j ("` cat $Full `") # make from config file | piped for number of rows wanted, remove pipe later
foreach j ("` cat $Full | head -20`") # make from config file | piped for number of rows wanted, remove pipe later
    set r_original = `echo $j | awk '{print $3}'` # the value of the radius in the image unit
    set x0 = `echo $j | awk '{print $1}'`
    set y0 = `echo $j | awk '{print $2}'`
    set r = `echo $j | awk '{print $3/'"$map_area"'*1000}'` # the value of the radius in the image unit

    rm -rf circle_line.dat
    foreach i (`seq 0 1 100`)
        set x = `echo "scale=10; $x0 - $r + (2 * $r) * $i / 100" | bc -l`
        set y1 = `echo "scale=10; sqrt($r * $r - ($x - $x0) * ($x - $x0)) + $y0" | bc -l`
        set y2 = `echo "scale=10; -sqrt($r * $r - ($x - $x0) * ($x - $x0)) + $y0" | bc -l`
        echo $x $y1 $r >> circle_line.dat 
        echo $x $y2 $r >> circle_line.dat
    end
    awk '{if($2<='"$y0"' && $1<='"$x0"') print $0}' circle_line.dat | sort -n -k1 > circ.dat
    awk '{if($2<='"$y0"' && $1>'"$x0"') print $0}' circle_line.dat | sort -n -k1 >> circ.dat
    awk '{if($2>='"$y0"' && $1>'"$x0"') print $0}' circle_line.dat | sort -n -r -k1 >> circ.dat
    awk '{if($2>='"$y0"' && $1<='"$x0"') print $0}' circle_line.dat | sort -n -r -k1 >> circ.dat
    #echo "how many lines should be "$counter
    if ( $Category_number > 1  ) then
        #if ( "$j" == "` cat $Full | head -1`" ) echo "You wish to set limits" endif
        foreach i (`seq 1 1 $Category_number`)
            set newthingforlower = `echo "scale=10; $Category_number - $i +2" | bc -l` # could be removed it there is a one-liner
            set newthingforupper = `echo "scale=10; $Category_number - $i +1 " | bc -l` # could be removed it there is a one-liner 
            set lower = `more minmax.txt | awk '{print $1/'"$map_area"'*1000}' | tail -$newthingforlower | head -1` # remove above and use head then tail
#            set lower = `more minmax.txt | awk '{print $1}' | tail -$newthingforlower | head -1` # remove above and use head then tail
            set upper = `more minmax.txt | awk '{print $1/'"$map_area"'*1000}' | tail -$newthingforupper | head -1`
            #echo "original radius is = " $r_original " the map  radius is = " $r " ,lower boundary is = " $lower " ,upper boundary is = " $upper "for line " $counter
  #          set lower1 = `more minmax.txt | awk '{print $1}' | tail -$newthingforlower | head -1` # remove above and use head then tail
 #           set upper1 = `more minmax.txt | awk '{print $1}' | tail -$newthingforupper | head -1`

            ##############ako  ovaj upper i lower ne radi onda koristi  set donja$i = $limits[$i]; set gornja$i = $limits[$i+1];
            if (`echo "$r >= $lower && $r < $upper" | bc -l` ) then
                grdmask circ.dat -R$min_x/$max_x/$min_y/$max_y -I$dx/$dx -NNaN/1/1  -Gmask_$lower\_to_$upper\.grd
                #echo "The radius " `echo "scale=3; $r_original*1000" | bc -l` "is inside the limits " `echo "scale=3; $lower*$map_area" | bc -l` " and " `echo "scale=3; $upper*$map_area" | bc -l` 

                if (-e themask_$lower\_to_$upper\.grd) then
                    grdmath mask_$lower\_to_$upper\.grd themask_$lower\_to_$upper\.grd AND = newmask_$lower\_to_$upper\.grd
                    mv newmask_$lower\_to_$upper\.grd themask_$lower\_to_$upper\.grd
                else
                    mv mask_$lower\_to_$upper\.grd themask_$lower\_to_$upper\.grd
                endif
            endif
        
        end
    #ode nema određenih limita pa se radi o broju kategorija. siguran san da bi ovo doli tribalo radit... testiraj za razlicite kategorije plus za grdmask
    else if ( $Category_number == 1  ) then 
    
        if ( "$j" == "` cat $Full | head -1`" ) echo "Categories are done based on incremental increase of average category bin"
        set min_r = `head -1 minmax.txt`
        set max_r = `tail -1 minmax.txt`
        
        set lower = `echo "scale=10; $min_r/$map_area*1000" | bc -l` # could be removed it there is a one-liner
        set upper = `echo "scale=10; $max_r/$map_area*1000" | bc -l` # could be removed it there is a one-liner
        #echo "The radius " $r_original  "in meters, is inside the limits " `echo "scale=7; $lower*$map_area/1000" | bc -l` " and " `echo "scale=7; $upper*$map_area/1000" | bc -l`

         
         if (`echo "$r >= $lower && $r < $upper" | bc -l` ) then
                #echo "inside the limit thing"  
                grdmask circ.dat -R$min_x/$max_x/$min_y/$max_y -I$dx/$dx -NNaN/1/1  -Gmask_$lower\_to_$upper\.grd
                if (-e themask_$lower\_to_$upper\.grd ) then
                    grdmath mask_$lower\_to_$upper\.grd themask_$lower\_to_$upper\.grd AND = newmask_$lower\_to_$upper\.grd
                    mv newmask_$lower\_to_$upper\.grd themask_$lower\_to_$upper\.grd
                else
                    mv mask_$lower\_to_$upper\.grd themask_$lower\_to_$upper\.grd
                endif
            endif
    else 
        echo "##################################################################################"
        echo "| Please chose if you want to use limits or categories, based your requirements  |" 
        echo "|                  In the configuration file chose 1 or 0                        |" 
        echo "##################################################################################"
        exit 1
    endif
        
    set  count100 = `echo $counter % 100 | bc`
    if ("$count100" == "0") then
        echo  "\e[32mNumber $counter is done\e[0m"
    endif
    set counter =  `expr $counter + 1`

    
end
echo "##################################################################################"
echo "|                 All grids are made to the specific requirements                |" 
echo "##################################################################################"

set nomask = `ls -v themask*.grd | wc -w` #mask issue
set allmask = `ls -v themask*.grd` # works
echo "Number of masks made = " $nomask " and they are  " 
echo $allmask
#set upper = `more minmax.txt | awk '{print $1}' | tail -$newthingforupper | head -1`
foreach j (`seq 1 1 $nomask`) 
    set powerof10 = `echo "scale=5; 10^$j" | bc -l`
    set maska = `echo $allmask | awk '{print $'$j'}' | awk -F'[grd]' '{print $1}'` # figure out later how to remove ".", when you do add "." to grdclip
echo "this is power of 10 = " $powerof10
echo "this is maska = " $maska
    grdclip $maska\grd -G$maska\_clp.grd -SrNaN/0 -Sr1/$powerof10 
end
#############################################################################################################################
#############################################################################################################################
set count = 1
set grid=""
foreach j (`ls -v themask*_clp.grd`) 
    if ( "$count" <= "1" ) then
        set grid = "$grid $j"
    else 
        set grid = "$grid $j ADD"
    endif
    set count =  `expr $count + 1`
end
echo "Grids included in the calculations are = " $grid
grdmath $grid = allcategoryADD_cons.grd 

set weight = ""
set temp = ""
set forvis = ""
rm -f expresions.txt powers.txt
echo "#################################################################################"
foreach j (`seq 1 1 $nomask`) # 1 1 3
if ( $Category_number == 1  ) then 
    set weight_value = 0
else 
    set weight_value = `more +13 config.txt | awk '{print 1-($2/100)}' | head -$j | tail -1`
endif
echo "this is the value of the weight = " $weight_value
    set powerof10 = `echo "scale=5; 10^$j" | bc -l` # 10 100 1000
    set power101 = `echo "scale=5; $powerof10-1" | bc -l`
    set power102 = `echo "scale=5; $powerof10*2" | bc -l`
    #echo "power of 10 -1 = "$power101 ", and power of 10 *1 = "$power102 
    #echo "this is the count = "$j
 
    if ( "$j" == "1" ) then #first
        set weight = "-Sr"$powerof10"/"$weight_value
        set weight = "$weight  "
        echo $weight >> expresions.txt
        set forvis = "-Sr"$powerof10"/"$j 
        set forvis = "$forvis "
        echo $forvis >> powers.txt

    else if ( "$j" == "$nomask" ) then #last
        #set weight = "-Sa"$powerof10"/"$weight_value
        set weight = "-Sa"$power101"/"$weight_value
        set weight = "$weight  "
        echo $weight >> expresions.txt
        set forvis = "-Si"$power101"/"$power102"/"` echo "scale=1; $j" | bc -l`
        set forvis = "$forvis "
        echo $forvis >> powers.txt

    else #middle
        set weight = "-Si"$power101"/"$power102"/"$weight_value
        set weight = "$weight "
        echo $weight >> expresions.txt
        set forvis = "-Si"$power101"/"$power102"/"` echo "scale=1; $j" | bc -l`
        set forvis = "$forvis "
        echo $forvis >> powers.txt

    endif
end
set temp2=""
foreach k ("`cat expresions.txt`") 
        set temp2 = "$temp2 $k"
end
echo "These numbers will be used for landing site analysis = -Sb10/1 "  $temp2


set temp1=""
foreach k ("`cat powers.txt`") 
    set temp1 = "$temp1 $k"
end
echo "These numbers will be used for visualisation = -Sb10/0 "  $temp1

grdclip allcategoryADD_cons.grd -GallcategoryADD_cons_clp_vis.grd -Sb10/0 $temp1 # this is for visualisation 
grdclip allcategoryADD_cons.grd -GallcategoryADD_cons_clp_wei.grd -Sb10/1 $temp2 # this is for analysis with weights

echo "j is = "$j 

makecpt -D -I -T0/` echo "scale=1; $j+1" | bc -l`/` echo "scale=2; ($j)/10" | bc -l` -Cpolar > colorbar.cpt
echo "newish thing"

# grdclip allcategoryADD_cons.grd -GallcategoryADD_cons_clp2.grd -Sb10/0.1 -Si99/200/0.35 -Si999/2000/0.35 -Sa9999/0.1
# grdclip allcategoryADD_cons.grd -GallcategoryADD_cons_clp3.grd -Sa999/0 -Si99.999/199.999/0.1 -Si9.999/19.999/0.4 -Si0.9999/1.9999/0.6 -Si0.099999/0.199999/0.8 -Sb0.019999/1 

#-1397.014221	167.514224	1825.484851	3038.515157	-2576.9	-2523.3	0	

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Visualisation of craters" -Bx+l"X[m]" -By+l"Y[m]" -K > Visualisation_of_craters.ps
grdimage allcategoryADD_cons_clp_vis.grd -JX10/0 -R$min_x/$max_x/$min_y/$max_y -Ccolorbar.cpt -K -O >> Visualisation_of_craters.ps
psscale -Ccolorbar.cpt -Dx1/-1.75+w8c+e+h -Baf -By+l"[m]" -R -J -O >> Visualisation_of_craters.ps
psconvert -P -A Visualisation_of_craters.ps

echo "Visualisation of craters is finished"


echo "##################################################################################"
echo "                          Gridmaker has finished running"
echo "##################################################################################"
