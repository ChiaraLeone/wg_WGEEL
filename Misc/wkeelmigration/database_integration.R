# 29/12/2019
# 
# Author: cedricbriandgithub
###############################################################################


# Initial read of seasonality files -------------------------------------------


# load packages set path ------------------------

setwd("C:\\workspace\\gitwgeel\\Misc\\wkeelmigration\\")
source("..\\..\\R\\utilities\\load_library.R")
source("functions.R")
load_package("readxl")
load_package("stringr")
load_package("pool")
load_package("DBI")
load_package("RPostgreSQL")
load_package("glue")
load_package("sqldf")
load_package("tidyverse")
load_package("ggforce") # better circular plots using ggplot

source("..\\..\\R\\shiny_data_integration\\shiny_di\\loading_functions.R")
source("..\\..\\R\\shiny_data_integration\\shiny_di\\database_reference.R") # extract_ref
load(file=str_c("C:\\workspace\\gitwgeel\\R\\shiny_data_integration\\shiny_di","\\common\\data\\init_data.Rdata"))  
datawd <- "C:\\Users\\cedric.briand\\OneDrive - EPTB Vilaine\\Projets\\GRISAM\\2020\\wkeemigration\\source\\"
datawd1 <- "C:\\Users\\cedric.briand\\OneDrive - EPTB Vilaine\\Projets\\GRISAM\\2020\\wkeemigration\\Treated commercial\\"

imgwd <- "C:\\workspace\\wgeeldata\\wkeelmigration\\image\\"

library("sf")
library("ggspatial")

dsn <-  paste0("PG:dbname='wgeel' host='localhost' port ='5436'",
		" user='", userlocal,
		"' password='", passwordlocal,"'")

##map of country
## remove mediterranean (no recruitment) and Island.
#query <- "SELECT cou_code,cou_country, geom  
#		FROM REF.tr_country_cou where cou_code not in ('IL','CY','DZ','EG','LY','MT','MA','IS','TR','LB','SY','TN')"
#cou <- st_read(dsn= dsn,  layer="country",query=query)
##plot(st_geometry(cou), xlim=c(-7,11.5),ylim=c(36,53))
#
## map of emus
#query <- "SELECT * FROM REF.tr_emu_emu WHERE emu_cou_code  IN ('FR','ES','PT') AND emu_wholecountry=FALSE"
#emu <- st_read(dsn= dsn, layer="i don't want no warning" , query=query)
#
## gets the centerpoints coordinates for the emus
#
#query <- "SELECT emu_nameshort, st_centroid(geom) as geom FROM REF.tr_emu_emu WHERE emu_cou_code  IN ('FR','ES','PT') AND emu_wholecountry=FALSE"
#emu_c <- st_read(dsn= dsn,  layer="emu",query=query)
## plot(st_geometry(emu))
## plot(emu_c, add=TRUE)
#
#save(cou, file=str_c(datawd,"cou.Rdata"))



# read data FROM DATABASE----------------------------------------------

fall <- list.files(datawd, pattern='.xl')
fcl <- list.files(datawd1,pattern='commercial_landings')
ffc <- list.files(datawd,pattern='fishery_closure')
fsm <- list.files(datawd,pattern='seasonality_of_migration')
# test for missing files
stopifnot(length(fall[!fall%in%c(fcl,ffc,fsm)])==0)

# load data from database
# At this stage start a tunnel to wgeel via SSH
port <- 5436 # 5435 to use with SSH, translated to 5432 on distant server
# 5436 to use in local server
host <- "localhost"#"192.168.0.100"
userwgeel <-"wgeel"
# we use isolate as we want no dependency on the value (only the button being clicked)
stopifnot(exists("passwordwgeel"))

# connection settings -------------------------------------------------------------------

#options(sqldf.RPostgreSQL.user = userwgeel,  
#		sqldf.RPostgreSQL.password = passwordwgeel,
#		sqldf.RPostgreSQL.dbname = "wgeel",
#		sqldf.RPostgreSQL.host = host, #getInformation("PostgreSQL host: if local ==> localhost"), 
#		sqldf.RPostgreSQL.port = port)
#
## Define pool handler by pool on global level
#pool <- pool::dbPool(drv = dbDriver("PostgreSQL"),
#		dbname="wgeel",
#		host=host,
#		port=port,
#		user= userwgeel,
#		password= passwordwgeel)
#
#
#
#query <- "SELECT column_name
#		FROM   information_schema.columns
#		WHERE  table_name = 't_eelstock_eel'
#		ORDER  BY ordinal_position"
#t_eelstock_eel_fields <- dbGetQuery(pool, sqlInterpolate(ANSI(), query))     
#t_eelstock_eel_fields <- t_eelstock_eel_fields$column_name
#
#query <- "SELECT cou_code,cou_country from ref.tr_country_cou order by cou_country"
#list_countryt <- dbGetQuery(pool, sqlInterpolate(ANSI(), query))   
#list_country <- list_countryt$cou_code
#names(list_country) <- list_countryt$cou_country
#list_country<-list_country
#
#query <- "SELECT * from ref.tr_typeseries_typ order by typ_name"
#tr_typeseries_typt <- dbGetQuery(pool, sqlInterpolate(ANSI(), query))   
#typ_id <- tr_typeseries_typt$typ_id
#tr_typeseries_typt$typ_name <- tolower(tr_typeseries_typt$typ_name)
#names(typ_id) <- tr_typeseries_typt$typ_name
## tr_type_typ<-extract_ref('Type of series') this works also !
#tr_typeseries_typt<-tr_typeseries_typt
#
#query <- "SELECT min(eel_year) as min_year, max(eel_year) as max_year from datawg.t_eelstock_eel eel_cou "
#the_years <<- dbGetQuery(pool, sqlInterpolate(ANSI(), query))   
#
query <- "SELECT name from datawg.participants"
participants<<- dbGetQuery(pool, sqlInterpolate(ANSI(), query))  
# save(participants,list_country,typ_id,the_years,t_eelstock_eel_fields, file=str_c(getwd(),"/common/data/init_data.Rdata"))
#ices_division <- extract_ref("FAO area")$f_code
#emus <- extract_ref("EMU")
#
#save(ices_division, emus, the_years, tr_typeseries_typt, list_country, file=str_c(datawd,"saved_data.Rdata"))
#
#poolClose(pool)

# load data seasonality ------------------------------------------------------------------------------
load( file=str_c(datawd,"saved_data.Rdata"))
load(file=str_c(datawd,"cou.Rdata"))



datasource <- "wkeelmigration"
list_seasonality <- list()
for (f in fsm){
	# f <- fsm[1]
	path <- str_c(datawd,f)	
	file<-basename(path)
	mylocalfilename<-gsub(".xlsx","",file)
	country <- substring(mylocalfilename,1,2)
	list_seasonality[[mylocalfilename]] <-	load_seasonality(path, datasource)
}
# list_seasonality is a list with all data sets (readme, data, series) as elements of the list
# below we extract the list of data and bind them all in a single data.frame
# to do so, I had to constrain the column type during file reading (see functions.R)
res <- map(list_seasonality,function(X){			X[["data"]]		}) %>% 
		bind_rows()
Hmisc::describe(res)
# correcting pb with column
#res$ser_nameshort[!is.na(as.numeric(res$das_month))]
#listviewer::jsonedit(list_seasonality)

# Correct month
unique(res$das_month)
res$das_month <- tolower(res$das_month)
res$das_month <- recode(res$das_month, okt = "oct")
res <-res[!is.na(res$das_month),]
res$das_month <- recode(res$das_month, 
		"mar"=3, 
		"apr"=4, 
		"may"=5, 
		"jun"=6,
		"jul"=7,
		"aug"=8,
		"sep"=9,
		"oct"=10,
		"nov"=11,
		"dec"=12, 
		"jan"=1, 
		"feb"=2
)

# check nameshort---------------------------------------------------------------
t_series_ser <- sqldf("SELECT
				ser_nameshort, 
				ser_namelong, 
				ser_typ_id,
				ser_effort_uni_code, 
				ser_comment,
				ser_uni_code, 
				ser_lfs_code, 
				ser_hty_code, 
				ser_locationdescription, 
				ser_emu_nameshort,
				ser_cou_code,
				ser_area_division, 
				ser_tblcodeid, 
				ser_x, 
				ser_y from datawg.t_series_ser")
ser_nameshort <- sqldf("select ser_nameshort from datawg.t_series_ser")
ser_nameshort <- as.character(ser_nameshort$ser_nameshort)
sort(ser_nameshort)

# replacing missing nameshort in France
# res[is.na(res$ser_nameshort),]
#res[is.na(res$ser_nameshort),"ser_nameshort"] <- res[is.na(res$ser_nameshort),] %>% 
#		pull(source)%>% 
#		gsub(pattern="FR_seasonality_of_migration_",replacement="")
# res$ser_nameshort <- gsub("-","",res$ser_nameshort)
# replacing values for nameshort with actual names when existing

ser_nameshort_datacall <- unique(res$ser_nameshort)
ser_nameshort_l <- tolower(ser_nameshort)
ser_nameshort_datacall_l <- tolower(ser_nameshort_datacall)
ccc <- charmatch(ser_nameshort_datacall_l,ser_nameshort_l,nomatch=-1) # partial character match, 
index <- ccc>0
#ser_nameshort_datacall_l[ccc==0]
# res[tolower(res$ser_nameshort)%in%c("bro","fla"),] # two with many names => corrected in the database
ser_nameshort_datacall_l[index]<-ser_nameshort[ccc[index]]
dfser <- data.frame(ser_nameshort=ser_nameshort_datacall, ser_nameshort_base="", existing=FALSE, stringsAsFactors = FALSE)
dfser$existing[index]<- TRUE
dfser$ser_nameshort_base[index]<-ser_nameshort[ccc[index]]


# load series data ------------------------------------------------------------------------------

ser <- map(list_seasonality,function(X){			X[["series_info"]]		}) %>% 
		bind_rows()
Hmisc::describe(ser)
ser <-ser[!is.na(ser$ser_nameshort),]
# searching for a mismatch between names in ser and the others (both must return zero)
print(ser[!ser$ser_nameshort%in%dfser$ser_nameshort,],width = Inf)
print(dfser$ser_nameshort[!dfser$ser_nameshort%in%ser$ser_nameshort]) 
ser2 <- merge(dfser,ser,by="ser_nameshort",all.x=TRUE,all.y=TRUE)
# replacing all existing series with data from base
ser2[ser2$existing,c(4:ncol(ser2))]<- t_series_ser[match(ser2[ser2$existing,"ser_nameshort_base"],t_series_ser$ser_nameshort),-1]

# check latitude
range(ser2$ser_y, na.rm = TRUE)

# switch coordinates for NL

index_problem_NL <- which(ser2$ser_y<20 & !is.na(ser2$ser_y))
xtemp <-ser2$ser_y[index_problem_NL]
ser2$ser_y[index_problem_NL] <- ser2$ser_x[index_problem_NL]
ser2$ser_x[index_problem_NL] <- xtemp ; rm(xtemp, index_problem_NL)

# some summaries about data --------------------------------------------------------------------
# 
nrow(res) #7764
nrow(ser2)
# test before joining that we not not loose any data
stopifnot(nrow(res %>%
						inner_join(ser2[,
										c("ser_nameshort",  "ser_lfs_code")], by="ser_nameshort"))==nrow(res))


# the following table are just copied and pasted in the markdown document readme.md file

# number per stage

knitr::kable(sum0 <- res %>%
				inner_join(ser2[,
								c("ser_nameshort",  "ser_lfs_code")], by="ser_nameshort") %>%
				group_by(ser_lfs_code) %>%
				summarize(N=n(), 
						Nseries=n_distinct(ser_nameshort)))

# number per month
knitr::kable(sum0 <- res %>%
				inner_join(ser2[,
								c("ser_nameshort",  "ser_lfs_code")], by="ser_nameshort") %>%
				group_by(ser_lfs_code,das_month) %>%
				summarize(N=n()) %>% pivot_wider(names_from="das_month",values_from="N")
)

# series details
knitr::kable(sum1 <- res %>%
				inner_join(ser2[,
								c("ser_nameshort", "ser_namelong", "ser_typ_id", "ser_lfs_code",  "ser_emu_nameshort", "ser_cou_code")], by="ser_nameshort") %>%
				group_by(ser_nameshort,ser_lfs_code, ser_cou_code) %>%
				summarize(first.year=min(das_year),last.year= max(das_year), nb_year=1+max(das_year)-min(das_year),N=n()))

save(res, ser2, file=str_c(datawd,"seasonality_tibbles_res_ser2.Rdata"))

#load(file=str_c(datawd,"seasonality_tibbles_res_ser2.Rdata"))


# Some plots  -------------------------------------------------

#scaledf <- function(x){
#	(x-mean(x, na.rm=TRUE))  / sd(x, na.rm=TRUE)
#}
#
#scalemax <- function(x){
#	x / max(x, na.rm=TRUE)
#}


# summarize the data set, first join usefull columns lfs code and ser_y from ser, 
# then calculate sum value for each series each year and join it back into the data set
# using the leading inner_join then calculate percentage per month which will fall between 0 and 1
# some trials about latitude show that this one seems to be working well for the glass eel plot below so I try to
# "discretize" the latitude

res3 <- left_join(res,
				res %>%		inner_join(ser2[,
										c("ser_nameshort",  "ser_lfs_code","ser_x","ser_y")], by="ser_nameshort") %>%
						group_by(ser_nameshort, das_year,ser_lfs_code, ser_y, ser_x) %>% 
						summarize(sum_per_year=sum(das_value,na.rm=TRUE)),
				by = c("ser_nameshort", "das_year")) %>%	
		mutate(perc_per_month=das_value/sum_per_year) %>% 
		mutate(lat_range=cut(ser_y,breaks=c(0,10,15,20,25,30,35,40,50,60,65,70)))

# example using ggplot and coord polar => not the best, problem with margins
png(filename=str_c(imgwd,"seasonality_glass_eel_wrong.png"))
#x11()
res3 %>% filter(ser_lfs_code=='G') %>%
		group_by(ser_nameshort, lat_range, das_month) %>%
		summarize(average_per_per_month=mean(perc_per_month,na.rm=TRUE)) %>%
		ggplot(aes(x = das_month,
						fill = ser_nameshort)) +
		geom_col(aes(y=average_per_per_month)) + 
		#facet_wrap(~ser_nameshort)+
		xlab("month")+
		geom_text(aes(x=das_month, y=4,label = das_month), color = "navy", size=3)+
		facet_grid(~lat_range )+
		coord_polar()+		
		theme_void()
dev.off()		


# using a different approach with geom_arc_bar
# https://rviews.rstudio.com/2019/09/19/intro-to-ggforce/
# https://stackoverflow.com/questions/16184188/ggplot-facet-piechart-placing-text-in-the-middle-of-pie-chart-slices/47645727#47645727


# COMPUTE DATA FRAME FOR GLASS EEL WITH EXPLICIT ANGLES
resG <- left_join(
				
				res3 %>% filter(ser_lfs_code=='G') %>%
						group_by(ser_nameshort, ser_x, ser_y, lat_range, das_month) %>%   # this will also arrange the dataset
						summarize(sum_per_month=sum(das_value,na.rm=TRUE))
				,
				res3 %>% group_by (ser_nameshort) %>%
						summarize(sum_per_series=sum(das_value,na.rm=TRUE),
								nyear=n_distinct(das_year)),			
				
				by = c("ser_nameshort") 
		
		) %>%
		ungroup() %>%
		rename(month=das_month, series=ser_nameshort) %>%
		mutate(perc_per_month = sum_per_month / sum_per_series,
				series=str_c(series, "N=", nyear)) %>%
		group_by(series) %>%
		mutate(
				end_angle = 2*pi*(month-1)/12,
				start_angle = 2*pi*(month)/12
				
		) # for text label


# overall scaling for pie size
scale = max(sqrt(resG$perc_per_month))

dflab <- data.frame(month=c(1:12), 
		angle = 2*pi*(1:12-0.5)/12,
		end_angle = 2*pi*(1:12-1)/12,
		start_angle = 2*pi*(1:12)/12)
resG$lab

Y <-resG %>% group_by(series) %>% 
		summarize(y=first(ser_y))%>%pull(y)

# series ordered by latitude
resG$series <- factor(resG$series, levels= levels(as.factor(resG$series))[order(Y)])
# draw the circular plot
png(filename=str_c(imgwd,"seasonality_glass_eel.png"))
ggplot(resG) + 
		geom_arc_bar(aes(x0 = 0, y0 = 0, r0 = 0, r = scale,
						start = start_angle, end = end_angle, fill = as.factor(month)),color="grey80",alpha=0, data=dflab)+
		geom_arc_bar(aes(x0 = 0, y0 = 0, r0 = 0, r = sqrt(perc_per_month),
						start = start_angle, end = end_angle, fill = as.factor(month))) +
		geom_text(aes(x = 1.2*scale*sin(angle), y = 1.2*scale*cos(angle), label = month), data=dflab,
				hjust = 0.5, vjust = 0.5, col="grey50", size=3) +
		coord_fixed() +
		scale_fill_manual("month",values=rainbow(12))+
		scale_x_continuous(limits = c(-1, 1), name = "", breaks = NULL, labels = NULL) +
		scale_y_continuous(limits = c(-1, 1), name = "", breaks = NULL, labels = NULL) +
		ggtitle("Seasonality for glass eel migration, series ordered by latitude")+
		hrbrthemes::theme_ipsum_rc()+
		facet_wrap(~series) 
dev.off()

# draw a map




png(filename=str_c(imgwd,"map_seasonality_glass_eel.png"),width = 10, height = 8, units = 'in', res = 300)
ggplot(data = cou) +  geom_sf(fill= "antiquewhite") +
		geom_arc_bar(aes(x0 = ser_x, y0 = ser_y, r0 = 0, r = 3*sqrt(perc_per_month),
						start = start_angle, end = end_angle, fill = as.factor(month)), 
				data=resG, 
				show.legend=FALSE,
				alpha=0.5) +		
		scale_colour_manual(values=cols)+
		scale_size_continuous(range=c(0.5,15)) +
		xlab("Longitude") + 
		ylab("Latitude") + 
		ggtitle("glass eel seasonality")+ 
		annotation_scale(location = "bl", width_hint = 0.5) +
		annotation_north_arrow(location = "tr", which_north = "true", 
				pad_x = unit(0.75, "in"), pad_y = unit(0.5, "in"),
				style = north_arrow_fancy_orienteering) +
		coord_sf(xlim=c(-10,12),ylim=c(42,60))+
		theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), 
				panel.background = element_rect(fill = "aliceblue"))
dev.off()


#####################################################
# Silver eel
####################################################

resS <- left_join(
				
				res3 %>% filter(ser_lfs_code=='S') %>%
						group_by(ser_nameshort, ser_x, ser_y, lat_range, das_month) %>%   # this will also arrange the dataset
						summarize(sum_per_month=sum(das_value,na.rm=TRUE))
				,
				res3 %>%  filter(ser_lfs_code=='S')%>% group_by (ser_nameshort) %>%
						summarize(sum_per_series=sum(das_value,na.rm=TRUE),
								nyear=n_distinct(das_year)),			
				
				by = c("ser_nameshort") 
		
		) %>%
		ungroup() %>%
		rename(month=das_month, series=ser_nameshort) %>%
		mutate(perc_per_month = sum_per_month / sum_per_series,
				series=str_c(series, "N=", nyear)) %>%
		group_by(series) %>%
		mutate(
				end_angle = 2*pi*(month-1)/12,
				start_angle = 2*pi*(month)/12
		
		) # for text label

resSs <- st_as_sf(resS[!is.na(resS$ser_y),], coords = c("ser_x", "ser_y"), crs = 4326)
resSs <- st_transform(x = resSs, crs = 3035)
resSs$lon<-st_coordinates(resSs)[,1]
resSs$lat<-st_coordinates(resSs)[,2]
st_bbox(resSs)
png(filename=str_c(imgwd,"map_seasonality_silver_eel.png"),width = 10, height = 8, units = 'in', res = 300)
ggplot(data = cou) +  
		geom_sf(fill= "antiquewhite") +
				coord_sf(crs = "+init=epsg:3035",
						xlim=c(3,6)*10^6,	
						ylim=	st_bbox(resSs)[c(2,4)]
				) +
		geom_arc_bar(aes(x0 = lon, y0 = lat, r0 = 0, r = 2*10^5*sqrt(perc_per_month),
						start = start_angle, end = end_angle, fill = as.factor(month)), 
				data=resSs, 
				show.legend=FALSE,
				alpha=0.5) +		
		scale_colour_manual(values=cols)+
		scale_size_continuous(range=c(0.5,15)) +
		xlab("Longitude") + 
		ylab("Latitude") + 
		ggtitle("silver eel seasonality")+ 
		annotation_scale(location = "bl", width_hint = 0.5) +
		annotation_north_arrow(location = "tr", which_north = "true", 
				pad_x = unit(0.75, "in"), pad_y = unit(0.5, "in"),
				style = north_arrow_fancy_orienteering) +	
		theme(panel.grid.major = element_line(color = gray(.5), linetype = "dashed", size = 0.5), 
				panel.background = element_rect(fill = "aliceblue"))
dev.off()


png(filename=str_c(imgwd,"seasonality_silver.png"))
#x11()
res3 %>% filter(ser_lfs_code=='S') %>%
		
		ggplot(aes(x = das_month)) +
		geom_col(aes(y=perc_per_month, fill=ser_nameshort)) + 
		facet_wrap(~country)+
		xlab("month")

dev.off()		



#-----------------------------------------------------------------------------------------------------
# load data OTHER ------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------
load( file=str_c(datawd,"saved_data.Rdata"))
load(file=str_c(datawd,"cou.Rdata"))



datasource <- "wkeelmigration"
list_seasonality <- list()
for (f in fcl){
	# f <- fcl[1]
	path <- str_c(datawd1,f)	
	file<-basename(path)
	mylocalfilename<-gsub(".xlsx","",file)
	country <- substring(mylocalfilename,1,2)
	list_seasonality[[mylocalfilename]] <-	load_seasonality(path, datasource)
}
# list_seasonality is a list with all data sets (readme, data, series) as elements of the list
# below we extract the list of data and bind them all in a single data.frame
# to do so, I had to constrain the column type during file reading (see functions.R)
res <- map(list_seasonality,function(X){			X[["data"]]		}) %>% 
		bind_rows()
Hmisc::describe(res)
# correcting pb with column
#res$ser_nameshort[!is.na(as.numeric(res$das_month))]
#listviewer::jsonedit(list_seasonality)

# Correct month
unique(res$das_month)
res$das_month <- tolower(res$das_month)
res$das_month <- recode(res$das_month, okt = "oct")
res <-res[!is.na(res$das_month),]
res$das_month <- recode(res$das_month, 
		"mar"=3, 
		"apr"=4, 
		"may"=5, 
		"jun"=6,
		"jul"=7,
		"aug"=8,
		"sep"=9,
		"oct"=10,
		"nov"=11,
		"dec"=12, 
		"jan"=1, 
		"feb"=2
)
