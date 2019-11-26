#!/bin/tcsh

### has to be tested
#echo "how many line argmunets do I have" $#argv 
#echo $argv[1] 

if ($#argv != 1) then
    echo "Does not work, call like this 'all.tcsh config.txt' "
    exit 0
else
    echo "all good - name of config.txt is " $1
endif

set Results = `more +5 config.txt | head -1 | awk '{print $1}'`
set wTopography = `more +6 config.txt | head -1 | awk '{print $1}'`
set wSlope = `more +7 config.txt | head -1 | awk '{print $1}'`
set wRoughness = `more +8 config.txt | head -1 | awk '{print $1}'`
set wSigma = `more +9 config.txt | head -1 | awk '{print $1}'`
set wCrater = `more +10 config.txt | head -1 | awk '{print $1}'`
echo " Weight of Topography is" $wTopography
echo " Weight of Slope is" $wSlope
echo " Weight of Roughness is" $wRoughness
echo " Weight of Sigma is" $wSigma
echo " Weights of all Craters is" $wCrater

echo "The code will start running if you are satistfied with the weights"
echo "If not please change the weight in the configuration file"
echo "Previous Plots and Grids will be deleted, if you wish to keep the old results save them in a different folder"
echo "Do you want to continue? Write 1 for Yes, 0 for No" # put one
set yes_or_no = $<

if ($yes_or_no != 1 )  exit 0
echo " "
echo "---------------------------------------------------------------------------------"
echo "|                       THE CODE HAS STARTED TO RUN                             |"
echo "---------------------------------------------------------------------------------"

rm -rf Plots
rm -rf Grids
rm -rf all_grid_info.txt
if !(-e Separated_result.txt) then
    more $Results | sed 's/,/ /g' > Separated_result.txt
endif

if !( -e gmt.conf ) then
    #more Results* | sed 's/,/ /g' > Separated_result.txt
    gmtset PROJ_ELLIPSOID 1737400.0,0 PROJ_LENGTH_UNIT cm COLOR_MODEL rgb PS_IMAGE_COMPRESS none
    gmtset MAP_ANNOT_MIN_SPACING 0.5 FONT_ANNOT_PRIMARY 10p,Helvetica,black FONT_LABEL 12p,Helvetica,black
    gmtset FONT_TITLE 14p,Helvetica,black
    gmtset MAP_FRAME_TYPE fancy MAP_FRAME_WIDTH 5p MAP_FRAME_PEN 0.6p MAP_TITLE_OFFSET 10p PS_PAGE_COLOR white
endif
#if !(-e DTM_topo.grd) then
   #awk '{print $1/1000, $2/1000, $3}' Separated_result.txt |   surface Mat_DTM_Result.ascii -GDTM_topo.grd -I0.005/0.005 -R-1.39701/0.167514/1.82548/3.03852 -T1 -C0.002
#   grdgradient DTM_topo.grd -A0 -Ne0.8 -GDTM_topo_intense.grd
#endif

#-705.500802093	2309.76800363
#awk '{print $1/1000, $2/1000, $3}' Separated_result.txt  > Mat_DTM_Result.ascii #mapproject -Js0/-90/1:1 -Fk -C -R-100/100/-100/100 

#########echo "90 0" | mapproject -Js30.6391/20.1198/1:1 -Fk -C -R-10000/10000/-10000/10000
#psscale -CDTM_Mat_H.cpt -Dx11c/8c+w8c+jTC+e -Baf -R -J -K -O >> DTM_Mat_H.ps

set dx = `echo "scale=10; 0.5" | bc -l`
set a = `echo "scale=10; 500 " | bc -l` 
set b = `echo "scale=10; 750 " | bc -l` 
set alfa = `echo "scale=10; 308.49 " | bc -l`
set x0 = `echo "scale=10; -705.5008 " | bc -l`
set y0 = `echo "scale=10; 2309.7680 " | bc -l`
set rad = `echo "scale=10; 3.1415926535/180 " | bc -l`
echo "$x0 $y0 $alfa $a $b" > ellipse.txt 

#################
gmtinfo -C Separated_result.txt > gmtfile_Sep.txt

set min_x = `awk '{print $1}'  gmtfile_Sep.txt `
set max_x = `awk '{print $2}'  gmtfile_Sep.txt `
set min_y = `awk '{print $3}'  gmtfile_Sep.txt `
set max_y = `awk '{print $4}'  gmtfile_Sep.txt `
set min_z = `awk '{print $5}'  gmtfile_Sep.txt `
set max_z = `awk '{print $6}'  gmtfile_Sep.txt `
set max_slope = `awk '{print $8}'  gmtfile_Sep.txt `
set max_roughness = `awk '{print $10}'  gmtfile_Sep.txt `
set max_sigma = `awk '{print $12}'  gmtfile_Sep.txt `
set Category_number = `more +12 config.txt | head -1 | awk '{print $1}'`

#rm -f gmtfile_Sep.txt # removed at the end because these are needed for gridmaker too
# -R-1397.01/167.514/1825.48/3038.52 
set col1=brown1
set col2=white #indianred1
set col3=royalblue
#              red                          white                 blue
echo  "0	$col1	0.33	$col1 \n0.33	$col2	0.66	$col2 \n0.66	$col3	1	$col3 \nB	$col1 \nF	$col3 \nN	127.5" > long.cpt
echo  "0	$col1	0.5	$col1 \n0.5	$col3	1	$col3 \nB	$col1 \nF	$col3 \nN	127.5" > short.cpt
echo  "0	$col3	5	$col3 \n5	$col2	10	$col2 \n10	$col1	15	$col1 \nB	$col3 \nF	$col1 \nN	127.5" > scale.cpt
###############################################################################################
echo "---------------------------------------------------------------------------------"
echo "|                       TOPOGRAPHY CALCULATION                                  |"
echo "---------------------------------------------------------------------------------"

if !(-e DTM_Mat_H.grd) then
    awk '{print $1, $2, $3}' Separated_result.txt  > Mat_DTM_Result_H.ascii
    surface Mat_DTM_Result_H.ascii -GDTM_Mat_H.grd -I$dx/$dx -R$min_x/$max_x/$min_y/$max_y -T0.5 -C0.002
    grdgradient DTM_Mat_H.grd -A0 -Ne0.8 -GDTM_Mat_intense_H.grd
endif
makecpt -Z -D -T-2580/-2520/1 -Cjet > DTM_Mat_H.cpt # for H
################original
#makecpt -D -T-2577/-2523/27 -Cpolar > DTM_Mat_H_cliped_scale.cpt # for H
#grdclip DTM_Mat_H.grd -GDTM_Mat_H_cliped.grd -Sa-2577/-2570
################new
#makecpt  -D -I -T0/1/0.5 -Cpolar > DTM_Mat_H_cliped.cpt
grdclip DTM_Mat_H.grd -GDTM_Mat_H_cliped.grd -Sb0/1

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Topography" -Bx+l"X[m]" -By+l"Y[m]" -K > DTM_Mat_H.ps
grdimage DTM_Mat_H.grd -IDTM_Mat_intense_H.grd  -JX10/0 -R$min_x/$max_x/$min_y/$max_y -CDTM_Mat_H.cpt -K -O >> DTM_Mat_H.ps
psscale -CDTM_Mat_H.cpt -Dx1/-1.75+w8c+e+h -Ba20f5 -By+l"[m]"  -R -J -K -O >> DTM_Mat_H.ps
psxy ellipse.txt -SE -R -J -O -W1 >> DTM_Mat_H.ps
psconvert -P -A  DTM_Mat_H.ps 

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Topography" -Bx+l"X[m]" -By+l"Y[m]" -K  > DTM_Mat_H_cliped.ps
grdimage DTM_Mat_H_cliped.grd -JX10/0 -R$min_x/$max_x/$min_y/$max_y -Cshort.cpt -K -O >> DTM_Mat_H_cliped.ps
psscale -Cshort.cpt -Dx1/-1.75+w8c+e+h -Ba0 -By+l"[m]"  -R -J -O >> DTM_Mat_H_cliped.ps
psconvert -P -A  DTM_Mat_H_cliped.ps

psbasemap -JX8/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Topography" -Bx+l"X[m]" -By+l"Y[m]" -K -Y13c  > All_map_color.ps
grdimage DTM_Mat_H.grd -IDTM_Mat_intense_H.grd -JX8/0 -R$min_x/$max_x/$min_y/$max_y -CDTM_Mat_H.cpt -K -O >> All_map_color.ps
psscale -CDTM_Mat_H.cpt -Dx0.75/-1.75+w6c+e+h -Ba20f5 -By+l"[m]"  -R -J -O -K >> All_map_color.ps

psbasemap -JX8/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Topography" -Bx+l"X[m]" -By+l"Y[m]" -K -Y13c  > All_map_color_cliped.ps
grdimage DTM_Mat_H_cliped.grd -JX8/0 -R$min_x/$max_x/$min_y/$max_y -Cshort.cpt -K -O >> All_map_color_cliped.ps
psscale -Cshort.cpt -Dx0.75/-1.75+w6c+e+h -Ba0 -By+l"[m]"  -R -J -O -K >> All_map_color_cliped.ps


echo "---------------------------------------------------------------------------------"
echo "|                       TOPOGRAPHY HAS BEEN CALCULATED                          |"
echo "---------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo "|                            SLOPE CALCULATION                                  |"
echo "---------------------------------------------------------------------------------"

if !(-e /DTM_Mat_Slope.grd) then
    awk '{print $1, $2, $4}' Separated_result.txt  > Mat_DTM_Result_Slope.ascii
    surface Mat_DTM_Result_Slope.ascii -GDTM_Mat_Slope.grd -I$dx/$dx -R$min_x/$max_x/$min_y/$max_y -T0.5 -C0.002
    grdgradient DTM_Mat_Slope.grd -A0 -Ne0.8 -GDTM_Mat_intense_Slope.grd
endif
makecpt -Z -D -T0/40/0.1 -Cjet > DTM_Mat_Slope.cpt # for Slope
#makecpt -D -Q -T-0.01/1.602/0.01 -Cjet > DTM_Mat_Slope.cpt # for all Slope logarithmic data
################original
#makecpt  -D -T0/15/5 -Cpolar > DTM_Mat_Slope_cliped_scale.cpt # for Slope
#grdclip DTM_Mat_Slope.grd -GDTM_Mat_Slope_cliped.grd -Sb5/4 -Si5/10/7 -Sa10/11
############new
#makecpt  -D -I -T0/1/0.33 -Cpolar > DTM_Mat_Slope_cliped.cpt
grdclip DTM_Mat_Slope.grd -GDTM_Mat_Slope_cliped.grd -Sb5/1 -Si5/10/0.5 -Sa10/0

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Slope" -Bx+l"X[m]" -By+l"Y[m]" -K > DTM_Mat_Slope.ps
grdimage DTM_Mat_Slope.grd  -JX10/0 -R$min_x/$max_x/$min_y/$max_y -K -O -CDTM_Mat_Slope.cpt >> DTM_Mat_Slope.ps
psscale -CDTM_Mat_Slope.cpt -Dx1/-1.75+w8c+e+h -Fc -Ba5f2.5 -By+l"[\260]"  -R -J -O -K >> DTM_Mat_Slope.ps
psxy ellipse.txt -SE -R -J -O -W1 >> DTM_Mat_Slope.ps
psconvert -P -A  DTM_Mat_Slope.ps

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Slope" -Bx+l"X[m]" -By+l"Y[m]" -K  > DTM_Mat_Slope_cliped.ps
grdimage DTM_Mat_Slope_cliped.grd -JX10/0 -R$min_x/$max_x/$min_y/$max_y -Clong.cpt -K -O >> DTM_Mat_Slope_cliped.ps
psscale -Cscale.cpt -Dx1/-1.75+w8c+e+h -Ba5 -By+l"[\260]" -R -J -O >> DTM_Mat_Slope_cliped.ps
psconvert -P -A  DTM_Mat_Slope_cliped.ps

psbasemap -JX8/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSwnE+t"Slope" -Bx+l"X[m]" -By+l"Y[m]" -K -O -X10c >> All_map_color.ps
grdimage DTM_Mat_Slope.grd  -JX8/0 -R$min_x/$max_x/$min_y/$max_y -CDTM_Mat_Slope.cpt -K -O >> All_map_color.ps
psscale -CDTM_Mat_Slope.cpt -Dx0.75/-1.75+w6c+e+h -Fc -Ba5f2.5 -By+l"[\260]"  -R -J -O -K >> All_map_color.ps


psbasemap -JX8/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSwnE+t"Slope" -Bx+l"X[m]" -By+l"Y[m]" -O -K -X10c >> All_map_color_cliped.ps
grdimage DTM_Mat_Slope_cliped.grd -JX8/0 -R$min_x/$max_x/$min_y/$max_y  -Clong.cpt -K -O >> All_map_color_cliped.ps
psscale -Cscale.cpt -Dx0.75/-1.75+w6c+e+h -Fc -Ba5 -By+l"[\260]"  -R -J -O -K >> All_map_color_cliped.ps

echo "---------------------------------------------------------------------------------"
echo "|                        SLOPE HAS BEEN CALCULATED                              |"
echo "---------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo "|                          ROUGHNESS CALCULATION                                |"
echo "---------------------------------------------------------------------------------"

echo  "0	$col3	0.05	$col3 \n0.05	$col2	0.1	$col2 \n0.1	$col1	0.15	$col1 \nB	$col3 \nF	$col1 \nN	127.5" > scale.cpt #scale change

if !(-e /DTM_Mat_R.grd) then
    awk '{print $1, $2, $5}' Separated_result.txt  > Mat_DTM_Result_R.ascii
    surface Mat_DTM_Result_R.ascii -GDTM_Mat_R.grd -I$dx/$dx -R$min_x/$max_x/$min_y/$max_y -T0.5 -C0.002
    grdgradient DTM_Mat_R.grd -A0 -Ne0.8 -GDTM_Mat_intense_R.grd
endif
#grdgradient DTM_Mat_R.grd -A0 -Ne0.8 -GDTM_Mat_intense_R.grd
#makecpt -D -Z -Q -T-1.35/-1.15/0.01  -Cjet > DTM_Mat_R.cpt # for roughness
makecpt -D -Z -Q -T-2/-0.85387/0.1  -Cjet > DTM_Mat_R.cpt # for all roughness data
################original
#makecpt  -T0/0.15/0.05 -Cpolar > DTM_Mat_R_cliped_scale.cpt # for roughness
#grdclip DTM_Mat_R.grd -GDTM_Mat_R_cliped.grd  -Sb0.07/0.04 -Si0.07/0.12/0.75 -Sa0.12/0.15
############new
makecpt  -D -I -T0/1/0.33 -Cpolar > DTM_Mat_R_cliped.cpt
grdclip DTM_Mat_R.grd -GDTM_Mat_R_cliped.grd  -Sb0.07/1 -Si0.07/0.12/0.5 -Sa0.12/0

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Roughness" -Bx+l"X[m]" -By+l"Y[m]" -K > DTM_Mat_R.ps
grdimage DTM_Mat_R.grd -IDTM_Mat_intense_R.grd -JX10/0 -R$min_x/$max_x/$min_y/$max_y -CDTM_Mat_R.cpt -K -O >> DTM_Mat_R.ps
psscale -CDTM_Mat_R.cpt -Dx1/-1.75+w8c+e+h -Baf -By+l"[m]" -R -J -O -K >> DTM_Mat_R.ps
psxy ellipse.txt -SE -R -J -W1 -O >> DTM_Mat_R.ps
psconvert -P -A  DTM_Mat_R.ps

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Roughness" -Bx+l"X[m]" -By+l"Y[m]" -K  > DTM_Mat_R_cliped.ps
grdimage DTM_Mat_R_cliped.grd -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Clong.cpt -K -O >> DTM_Mat_R_cliped.ps
psscale -Cscale.cpt -Dx1/-1.75+w8c+e+h -Fc -Baf -By+l"[m]" -R -J -O >> DTM_Mat_R_cliped.ps
psconvert -P -A  DTM_Mat_R_cliped.ps

psbasemap -JX8/0 -R$min_x/$max_x/$min_y/$max_y -Ba500f250 -BSWne+t"Roughness" -Bx+l"X[m]" -By+l"Y[m]" -O -K -Y-10c -X-10c >> All_map_color.ps
grdimage DTM_Mat_R.grd -JX8/0 -R$min_x/$max_x/$min_y/$max_y -CDTM_Mat_R.cpt -K -O >> All_map_color.ps
psscale -CDTM_Mat_R.cpt -Dx0.75/-1.75+w6c+e+h -Fc -Baf -By+l"[m]"  -R -J -O -K >> All_map_color.ps

psbasemap -JX8/0 -R$min_x/$max_x/$min_y/$max_y -Ba500f250 -BSWne+t"Roughness" -Bx+l"X[m]" -By+l"Y[m]" -O -K -Y-10c -X-10c >> All_map_color_cliped.ps
grdimage DTM_Mat_R_cliped.grd -JX8/0 -R$min_x/$max_x/$min_y/$max_y -Clong.cpt -K -O >> All_map_color_cliped.ps
psscale -Cscale.cpt -Dx0.75/-1.75+w6c+e+h -Fc -Ba -By+l"[m]" -R -J -O -K >> All_map_color_cliped.ps

echo "---------------------------------------------------------------------------------"
echo "|                       ROUGHNESS HAS BEEN CALCULATED                           |"
echo "---------------------------------------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo "|                            SIGMA CALCULATION                                  |"
echo "---------------------------------------------------------------------------------"
echo  "0	$col3	0.025	$col3 \n0.025	$col2	0.05	$col2 \n0.05	$col1	0.075	$col1 \nB	$col3 \nF	$col1 \nN	127.5" > scale.cpt #scale change

if !(-e /DTM_Mat_Sigma.grd) then
    awk '{print $1, $2, $6}' Separated_result.txt  > Mat_DTM_Result_Sigma.ascii
    surface Mat_DTM_Result_Sigma.ascii -GDTM_Mat_Sigma.grd -I$dx/$dx -R$min_x/$max_x/$min_y/$max_y -T0.5 -C0.002
    grdgradient DTM_Mat_Sigma.grd -A0 -Ne0.8 -GDTM_Mat_intense_Sigma.grd
endif
makecpt -D -Z -Q -T-1.7/-1.35/0.01 -Cjet > DTM_Mat_Sigma.cpt # for sigma
#makecpt -D -Z -Q -T-2.3/-1.15/0.11 -Cjet > DTM_Mat_Sigma.cpt # for all sigma data 
############original
#makecpt -D -T0/0.075/0.025 -Cpolar > DTM_Mat_Sigma_cliped_scale.cpt # for sigma
#grdclip DTM_Mat_Sigma.grd -GDTM_Mat_Sigma_cliped.grd -Sb0.03/0 -Si0.03/0.06/0.04 -Sa0.06/0.08
############new
makecpt  -D -I -T0/1/0.33 -Cpolar > DTM_Mat_Sigma_cliped.cpt
grdclip DTM_Mat_Sigma.grd -GDTM_Mat_Sigma_cliped.grd -Sb0.03/1 -Si0.03/0.05/0.5 -Sa0.05/0

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Sigma" -Bx+l"X[m]" -By+l"Y[m]" -K > DTM_Mat_Sigma.ps
grdimage DTM_Mat_Sigma.grd -IDTM_Mat_intense_Sigma.grd -JX10/0 -R$min_x/$max_x/$min_y/$max_y -CDTM_Mat_Sigma.cpt -K -O >> DTM_Mat_Sigma.ps
psscale -CDTM_Mat_Sigma.cpt -Dx1/-1.75+w8c+e+h -Ba0.01f0.005 -By+l"[m]" -R -J -O -K >> DTM_Mat_Sigma.ps
psxy ellipse.txt -SE -R -J -O -W1 >> DTM_Mat_Sigma.ps
psconvert -P -A  DTM_Mat_Sigma.ps

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Sigma" -Bx+l"X[m]" -By+l"Y[m]" -K > DTM_Mat_Sigma_cliped.ps
grdimage DTM_Mat_Sigma_cliped.grd -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Clong.cpt -K -O >> DTM_Mat_Sigma_cliped.ps
psscale -Cscale.cpt -Dx1/-1.75+w8c+e+h -Fc -Ba0.025 -By+l"[m]" -R -J -O >> DTM_Mat_Sigma_cliped.ps
psconvert -P -A  DTM_Mat_Sigma_cliped.ps

psbasemap -JX8/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSwnE+t"Sigma" -Bx+l"X[m]" -By+l"Y[m]" -O -K -X10c >> All_map_color.ps
grdimage DTM_Mat_Sigma.grd -JX8/0 -R$min_x/$max_x/$min_y/$max_y  -CDTM_Mat_Sigma.cpt -K -O >> All_map_color.ps
psscale -CDTM_Mat_Sigma.cpt -Dx0.75/-1.75+w6c+e+h -Fc -Ba0.01f0.005 -By+l"[m]"  -R -J -O >> All_map_color.ps
psconvert -P -A  All_map_color.ps

psbasemap -JX8/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSwnE+t"Sigma" -Bx+l"X[m]" -By+l"Y[m]" -O -K -X10c >> All_map_color_cliped.ps
grdimage DTM_Mat_Sigma_cliped.grd -JX8/0 -R$min_x/$max_x/$min_y/$max_y -Clong.cpt -K -O >> All_map_color_cliped.ps
psscale -Cscale.cpt -Dx0.75/-1.75+w6c+e+h -Fc -Ba0.025 -By+l"[m]" -R -J -O  >> All_map_color_cliped.ps
psconvert -P -A  All_map_color_cliped.ps

echo "---------------------------------------------------------------------------------"
echo "|                       SIGMA HAS BEEN CALCULATED                               |"
echo "---------------------------------------------------------------------------------"


psconvert -P -A  All_map_color_cliped.ps # if you want it in PDF then put "-Tf" at the end
psconvert -P -A  All_map_color.ps 
echo "---------------------------------------------------------------------------------"
echo "|                       ALL MAPS HAVE BEEN CALCULATED                           |"
echo "---------------------------------------------------------------------------------"
#grdclip DTM_Mat_H.grd -GDTM_Mat_H_cliped.grd -Sa-2580/1
#grdclip DTM_Mat_Slope.grd -GDTM_Mat_Slope_cliped.grd -Sb5/1 -Si5/10/0.5 -Sa10/0
#grdclip DTM_Mat_R.grd -GDTM_Mat_R_cliped.grd  -Sb0.07/1 -Si0.07/0.12/0.5 -Sa0.12/0
#grdclip DTM_Mat_Sigma.grd -GDTM_Mat_Sigma_cliped.grd -Sb0.03/1 -Si0.03/0.05/0.5 -Sa0.05/0

#grdmath DTM_Mat_Slope_cliped.grd 80 MUL = DTM_Mat_Slope_cliped_W.grd
#grdmath DTM_Mat_H_cliped.grd DTM_Mat_Slope_cliped.grd ADD  DTM_Mat_R_cliped.grd  ADD DTM_Mat_Sigma_cliped.grd  ADD 4 DIV  = Stacked.grd

#set max_x = `echo "scale=10; 167.514" | bc -l`
#set min_x = `echo "scale=10; -1397.01" | bc -l`

#set dxs = `echo "scale=10; ($max_x - $min_x)/(10*1000)" | bc -l`
#echo $dxs

#awk '{print $1, $2, $3 / '"$dxs"'}' Full_image_x_y_diameter__21_Oct_2019_17_49_space_separated.txt > Imagecraters.txt
#psxy Imagecraters.txt  -Sc -R -J  -Gblack >> cratersonmap.ps


./gridmaker.tcsh

makecpt -D -Z -T0/100/1 -Cseis > Stacked.cpt

grdmath DTM_Mat_H_cliped.grd $wTopography MUL 100 DIV = grid1.grd
grdmath DTM_Mat_Slope_cliped.grd $wSlope MUL 100 DIV = grid2.grd
grdmath DTM_Mat_R_cliped.grd $wRoughness MUL 100 DIV = grid3.grd
grdmath DTM_Mat_Sigma_cliped.grd $wSigma MUL 100 DIV = grid4.grd
grdmath allcategoryADD_cons_clp_wei.grd $wCrater MUL 100 DIV = grid5.grd

grdmath grid1.grd grid2.grd ADD grid3.grd ADD grid4.grd ADD grid5.grd ADD 100 MUL = Stacked_with_craters.grd

grdmath grid1.grd grid2.grd ADD grid3.grd ADD grid4.grd ADD 100 MUL = Stacked_without_craters.grd

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Stacked" -Bx+l"X[m]" -By+l"Y[m]" -K > Stacked_with_craters.ps
grdimage Stacked_with_craters.grd -JX10/0 -R$min_x/$max_x/$min_y/$max_y -CStacked.cpt -K -O >> Stacked_with_craters.ps
psscale -CStacked.cpt -Dx1/-1.75+w8c+e+h -Baf -By+l"[%]" -R -J -K -O >> Stacked_with_craters.ps
psxy ellipse.txt -SE -R -J -W1 -O >> Stacked_with_craters.ps
psconvert -P -A  Stacked_with_craters.ps

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Stacked" -Bx+l"X[m]" -By+l"Y[m]" -K > Stacked_without_craters.ps
grdimage  Stacked_without_craters.grd -JX10/0 -R$min_x/$max_x/$min_y/$max_y -CStacked.cpt -K -O >> Stacked_without_craters.ps
psscale -CStacked.cpt -Dx1/-1.75+w8c+e+h -Baf -By+l"[%]" -R -J -K -O >> Stacked_without_craters.ps
psxy ellipse.txt -SE -R -J -W1 -O >> Stacked_without_craters.ps
psconvert -P -A  Stacked_without_craters.ps


################## IF GRIDS ARE NOT DONE USE THE GRID MAKER
#################

#grdclip allcategoryADD_cons.grd -GallcategoryADD_cons_clp.grd -Sa999/0 -Si99.999/199.999/0.1 -Si9.999/19.999/0.4 -Si0.9999/1.9999/0.6 -Si0.099999/0.199999/0.8 -Sb0.019999/1 

# 
# grdmath Stacked.grd allcategoryADD_cons_clp_wei.grd ADD 2 DIV 100 MUL = Stacked_with_cratersADD.grd
# 
# 
# psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Stacked with craters weighted" -Bx+l"X[m]" -By+l"Y[m]" -K > Stacked_with_craters_finale.ps
# grdimage Stacked_with_cratersADD.grd -JX10/0 -R$min_x/$max_x/$min_y/$max_y -CStacked.cpt -K -O >> Stacked_with_craters_finale.ps
# psscale -CStacked.cpt -Dx1/-1.75+w8c+e+h -Baf -By+l"[%]" -R -J -O -K >> Stacked_with_craters_finale.ps
# psxy ellipse.txt -SE -R -J -W1 -O >> Stacked_with_craters_finale.ps
# psconvert -P -A  Stacked_with_craters_finale.ps
# echo "Stacked with craters finale is finished"
makecpt  -D -Z -T0/100/1 -Cseis > Stacked.cpt 


grdmath allcategoryADD_cons_clp_vis.grd Stacked_without_craters.grd  ADD 2 DIV 100 MUL = Stacked_with_cratersADDvis.grd

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Visualisation of craters and maps" -Bx+l"X[m]" -By+l"Y[m]" -K > Visualisation_of_craters_and_maps.ps
grdimage Stacked_with_cratersADDvis.grd -JX10/0 -R$min_x/$max_x/$min_y/$max_y -CStacked.cpt -K -O >> Visualisation_of_craters_and_maps.ps
psscale -CStacked.cpt -Dx1/-1.75+w8c+e+h -Baf -By+l"[%]" -R -J -O -K >> Visualisation_of_craters_and_maps.ps
psxy ellipse.txt -SE -R -J -W1 -O >> Visualisation_of_craters_and_maps.ps
psconvert -P -A  Visualisation_of_craters_and_maps.ps

echo "Visualisation of craters and maps is finished"
echo "---------------------------------------------------------------------------------"
echo "|                BOTH WEIGHTED AND VISUALISED MAPS HAVE BEEN MADE               |"
echo "---------------------------------------------------------------------------------"

set alfa = 320
echo "$x0 $y0 $alfa $a $b" > ellipse.txt

grd2xyz  Stacked_with_craters.grd | awk '{if (( ( ( ( cos( '"$alfa"' * '"$rad"') * ( $1 - '"$x0"' ) + sin( '"$alfa"' * '"$rad"') * ( $2 - '"$y0"' ) ) ^ 2 ) / ( ('"$a"'/2) ^ 2 ) ) + ( ( ( sin ( '"$alfa"' * '"$rad"' ) * ( $1 - '"$x0"' ) - cos('"$alfa"' *  '"$rad"' ) * ( $2 - '"$y0"' ) ) ^ 2 ) / ( ('"$b"'/2) ^ 2 ) ) ) <= 1 ) print $0}' |  psxy -JX10/0  -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -Gblack -Sx0.01 -K > ellipse_map.ps

set probability = `grd2xyz  Stacked_with_craters.grd | awk 'BEGIN {sum = 0; i = 0} {if (( ( ( ( cos( '"$alfa"' * '"$rad"') * ( $1 - '"$x0"' ) + sin( '"$alfa"' * '"$rad"') * ( $2 - '"$y0"' ) ) ^ 2 ) / ( ('"$a"'/2) ^ 2 ) ) + ( ( ( sin ( '"$alfa"' * '"$rad"' ) * ( $1 - '"$x0"' ) - cos('"$alfa"' *  '"$rad"' ) * ( $2 - '"$y0"' ) ) ^ 2 ) / ( ('"$b"'/2) ^ 2 ) ) ) <= 1 ){sum = sum + $3; i = i + 1} } END { print sum / i}'`

echo "---------------------------------------------------------------------------------"
echo "|     Final probability of landing inside the ellipse is " $probability "%      |"
echo "---------------------------------------------------------------------------------"

set alfa = 310
mv ellipse_map.ps ellipse_map$alfa.ps
echo "$x0 $y0 $alfa $a $b" > ellipse$alfa.txt
psxy ellipse$alfa.txt -SE -R -J -W1,red,.- -O >> ellipse_map$alfa.ps
echo "Elipse is printed"
psconvert -P -A  ellipse_map$alfa.ps

grdclip allcategoryADD_cons.grd -GallcategoryADD_cons_clp_old.grd -Sb10/1 -Si99/200/0.8 -Si999/2000/0.6 -Si9999/20000/0.4 -Si99999/200000/0.1 -Si999999/2000000/0
grdmath Stacked_without_craters.grd  allcategoryADD_cons_clp_old.grd ADD 2 DIV 100 MUL = Stacked_with_cratersADD_old.grd
makecpt  -D -Z -T0/100/1 -Cseis > Stacked.cpt

psbasemap -JX10/0 -R$min_x/$max_x/$min_y/$max_y  -Ba500f250 -BSWne+t"Stacked with craters weighted old file" -Bx+l"X[m]" -By+l"Y[m]" -K > oldvis.ps
grdimage Stacked_with_cratersADD_old.grd -JX10/0 -R$min_x/$max_x/$min_y/$max_y -CStacked.cpt -K -O >> oldvis.ps
psscale -CStacked.cpt -Dx1/-1.75+w8c+e+h -Baf -By+l"[%]" -R -J -O -K >> oldvis.ps
psxy ellipse.txt -SE -R -J -W1 -O >> oldvis.ps
psconvert -P -A  oldvis.ps



##### removing unnecessary things
set dateandtime = ` date +%F_%T |  sed s/-/_/g  | sed s/:/_/g `
#############delete later
mkdir Plots_$dateandtime\_cat_$Category_number
mv *.jpg Plots_$dateandtime\_cat_$Category_number
# mv Plots_$dateandtime\_cat_$Category_number ../
mkdir Grids
mv *.grd Grids
#grdinfo of all grids
cd Grids
foreach j ("` ls -v *.grd`")
    set information = `grdinfo -C $j`
    echo $information >> info_grids.txt
end
mv info_grids.txt ../
cd ..
rm -f *.ps *.ascii circ.dat circle_line.dat gmtfile_Sep.txt gmtfile_Full.txt  ellipse310.txt ellipse.txt  min_R.txt max_R.txt minmax.txt
rm -f *.cpt weights.txt Separated_result.txt limits.txt powers.txt expresions.txt

echo "The Folder will be changed to this name: Analysis_"$Category_number"_of_cat_"$dateandtime

echo "---------------------------------------------------------------------------------"
echo "|                       THE CODE HAS FINISHED RUNNING                           |"
echo "|                       ALL MAPS ARE IN THE FOLDER PLOTS                        |"
echo "|                       ALL GRIDS ARE IN THE FOLDER GRIDS                       |"
echo "---------------------------------------------------------------------------------"

#psscale -CDTM_Mat_Sigma.cpt -Dx11c/8c+w8c+jTC+e -Ba3f3 -R -J -K -Q -O  >> DTM_Mat_Sigma.ps  old scale
# -R-1397.01/167.514/1825.48/3038.52

echo "On the day and time : " $dateandtime "with this amount of categories: " $Category_number " the probability of landing was: " $probability >> all_result_temp.txt


set dir_change = ` pwd | grep -o '[^/]*$' `
cd ..
mv "$dir_change"/ Analysis_"$Category_number"_of_cat_"$dateandtime"


if !(-e ALL_RESULT.txt ) then
    mv Analysis_"$Category_number"_of_cat_"$dateandtime"/all_result_temp.txt ALL_RESULT.txt
else 
    mv ALL_RESULT.txt temp_of_all.txt
    cat temp_of_all.txt Analysis_"$Category_number"_of_cat_"$dateandtime"/all_result_temp.txt > ALL_RESULT.txt
    rm -f temp_of_all.txt
endif

















