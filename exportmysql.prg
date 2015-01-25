**start of program** 

** Created by Ajay Bramhe **
** For GemsDB project **
** You will need small customization for useing it **

PARAMETERS mdbf 

*mdbf="ajbtable"

mdbffile = mdbf + ".dbf" 
* where you want mysqldump files to go 
mexportfile = "W:\GEM2MYSQL\" + mdbf + ".sql" 
* where dbf files are 

*messagebox(mdbffile)
*messagebox(mexportfile)

SET DEFAULT TO W:\AK2010\prod
IF !FILE(mdbffile)
messagebox("not a valid file") 
CANCEL 
ENDIF 
set century on 
set hours to 24 
mjunk = 0 
* 
* open/create file to hold sql commands 
*	target is a linux box so only lf "chr(10)" at end of line 
*
*delete sql dump file if exists (important) 
DELETE FILE &mexportfile 
IF FILE(mexportfile) && Does file exist? 
mimporthandle = FOPEN(mexportfile,11) && If so, open write only 
ELSE 
mimporthandle = FCREATE(mexportfile) && If not, create it 
ENDIF 
IF mimporthandle < 1 
messagebox("could not open output file") 
CANCEL 
ENDIF 
use &mdbf 
set safety off 
*remove deleted records 
pack 
go top 
* 
* setup array to hold field attributes 
* 
mfield_cnt = AFIELDS(marray) && Create array 
* 
* Create text to build create table commands 
* 
mtext = "DROP TABLE IF EXISTS `" + mdbf + "`;" + chr(10) 
mjunk = FWRITE(mimporthandle, mtext) 
mtext = "CREATE TABLE IF NOT EXISTS `" + mdbf + "`(" + chr(10) 
mjunk = FWRITE(mimporthandle, mtext) 
FOR nCount = 1 TO mfield_cnt 
mtext = "" 
mtext = "`" + marray(nCount,1) + "` " && field name 
DO CASE 
CASE marray(nCount,2) = "C" 
mtext = mtext + "varchar(" + alltrim(str(marray(nCount,3))) + ") " 
CASE INLIST(marray(nCount,2), 'N', 'F', 'B') 
mtext = mtext + "decimal(" + alltrim(str(marray(nCount,3))) + "," + alltrim(str(marray(nCount,4))) + ") " 
CASE marray(nCount,2) = "D" 
mtext = mtext + "date " 
CASE marray(nCount,2) = "L" 
mtext = mtext + "tinyint(1) " 
CASE marray(nCount,2) = "I" 
mtext = mtext + "int(" + alltrim(str(marray(nCount,3))) + ") " 
CASE marray(nCount,2) = "T" 
mtext = mtext + "datetime " 
CASE marray(nCount,2) = "M" 
mtext = mtext + "text " 
OTHERWISE 
mtext = mtext + "unknown data type " 
ENDCASE 
if !marray(nCount, 5) 
mtext = mtext + "NOT NULL" 
endif 
if nCount < mfield_cnt	
mtext = mtext + "default '" + marray(nCount,9) +  "'," + chr(10) 
else 
mtext = mtext + "default '" + marray(nCount,9) +  "'" + chr(10) 
endif 
mjunk = FWRITE(mimporthandle, mtext)	
ENDFOR 
* 
* final line for create table section 
* 
mtext = ")TYPE=MyISAM COMMENT='" + mdbf + "';" + chr(10) + chr(10) 
mjunk = FWRITE(mimporthandle, mtext)	
go top 
* 
* start data loading section 
* 
do while !eof() 
* 
*beginning of line 
* 
mtext = "INSERT INTO " + mdbf + " VALUES (" 
FOR nCount = 1 TO mfield_cnt 
* 
*build values 
* 
if nCount > 1 && don't put a comma in the first time 
mtext = mtext + ", " 
endif 
DO CASE 
CASE marray(nCount,2) = "C"	&& characters 
if !isnull(&marray(nCount,1)) 
mtext = mtext + "'" + strtran(alltrim(&marray(nCount,1)), "'", "\'") + "'" 
else 
mtext = mtext + "'NULL'" 
endif 
CASE INLIST(marray(nCount,2), 'N', 'F', 'B') && numeric,float,double 
if !isnull(&marray(nCount,1)) 
mlen = marray(nCount,3) 
mdec = marray(nCount,4) 
mtext = mtext + "'" + alltrim(str(&marray(nCount,1),mlen,mdec)) + "'" 
else 
mtext = mtext + "'NULL'" 
endif 
CASE marray(nCount,2) = "I"	&& Integer 
if !isnull(&marray(nCount,1)) 
mtext = mtext + "'" + alltrim(str(&marray(nCount,1))) + "'" 
else 
mtext = mtext + "'NULL'" 
endif 
CASE marray(nCount,2) = "D" && date 
if !isnull(&marray(nCount,1)) 
mtext = mtext + "'" + substr(dtos(&marray(nCount,1)), 1, 4) 
mtext = mtext + "-" + substr(dtos(&marray(nCount,1)), 5, 2) 
mtext = mtext + "-" + substr(dtos(&marray(nCount,1)), 7, 2) + "'" 
else 
mtext = mtext + "'NULL'" 
endif 
CASE marray(nCount,2) = "T" && date time 
if !isnull(&marray(nCount,1)) 
mtext = mtext + "'" + substr(dtos(&marray(nCount,1)), 1, 4) 
mtext = mtext + "-" + substr(dtos(&marray(nCount,1)), 5, 2) 
mtext = mtext + "-" + substr(dtos(&marray(nCount,1)), 7, 2) 
mtext = mtext + " " + substr(ttoc(&marray(nCount,1)), 12, 8) + "'" 
else 
mtext = mtext + "'NULL'" 
endif 
CASE marray(nCount,2) = "L"	&& logical 
if !isnull(&marray(nCount,1)) 
if (&marray(nCount,1)) 
mtext = mtext + "'1'" 
else 
mtext = mtext + "'0'" 
endif 
else 
mtext = mtext + "'NULL'" 
endif 
CASE marray(nCount,2) = "M" && memo 
if !isnull(&marray(nCount,1)) 
if memlines(&marray(nCount,1)) = 0 
mtext = mtext + "''" 
else 
STORE MEMLINES(&marray(nCount,1)) TO gnNumLines 
mtext = mtext + "'" 
FOR gnCount = 1 TO gnNumLines 
mtext = mtext + strtran(alltrim(MLINE(&marray(nCount,1), gnCount)), "'", "\'") 
NEXT 
mtext = mtext + "'" 
endif	
else 
mtext = mtext + "'NULL'" 
endif 
OTHERWISE 
mtext = mtext + "unknown data type " 
ENDCASE 
if isnull(mtext) 
set step on 
endif 
* 
*end of data load line 
* 
ENDFOR 
mtext = mtext + ");" + chr(10) 
mjunk = FWRITE(mimporthandle, mtext)	
skip 
enddo 
use 
fclose(mimporthandle)
