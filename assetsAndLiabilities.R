# Title     : Assets and liabilities
# Objective : Create a report that gives a time series of assets and liabilities
# Created by: Michiel Rop
# Created on: 29/06/2019
# install.packages("DBI")
# install.packages("RMySQL")


library(RMySQL)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(tidyr)
library(sys)

mydb = dbConnect(MySQL(), user='root', password='supersecret', dbname='gnucash', host='127.0.0.1')

assetsResultSet = dbSendQuery(mydb,"select post_date, account_type as type, splits.value_num/100 as amount  FROM accounts
inner JOIN splits ON accounts.guid=splits.account_guid
inner JOIN transactions ON transactions.guid=splits.tx_guid
where account_type='ASSET'
order by post_date, type")

assetsDateFrame = fetch(assetsResultSet,n=-1)   %>% mutate(date = as.Date(post_date)) %>% mutate(total_assets = cumsum(coalesce( amount, 0))) %>% filter(date >=as.Date('2017-05-01'))

liabilitiesResultSet = dbSendQuery(mydb,"select post_date, account_type as type, splits.value_num/100 as amount  FROM accounts
inner JOIN splits ON accounts.guid=splits.account_guid
inner JOIN transactions ON transactions.guid=splits.tx_guid
where account_type='LIABILITY'
order by post_date, type")

liabilityDataFrame = fetch(liabilitiesResultSet,n=-1)  %>% mutate(date = as.Date(post_date)) %>% mutate(total_liabilities = cumsum(coalesce( amount, 0))) %>% filter(date >=as.Date('2017-05-01'))

write.table(assetsDateFrame)
write.table(liabilityDataFrame)

ggplot() +
    geom_line(data = liabilityDataFrame, aes(x = date, y = total_liabilities), color = "red") +
    geom_line(data = assetsDateFrame, aes(x = date, y = total_assets), color = "green")  + 
    xlab('date') +  ylab('amount') 


ggsave(paste(format(Sys.Date(), "%Y%m%d"), "assetsLiabilities.pdf",sep=""))

lapply( dbListConnections( dbDriver( drv = "MySQL")), dbDisconnect)



