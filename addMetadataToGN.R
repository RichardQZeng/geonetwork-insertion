library(geonapi)
library(geometa)
library(uuid)
library(stringr)

working_dir = getwd()

# Read params
datasets <- read.csv(file=paste0(working_dir, "/params/datasets.csv"),  sep = ",")
csv_error <- data.frame()

for (dataset in datasets$n){
  print(paste0("Working on: ", datasets$Title.Identifier..if.no.DOI.available.[dataset]))
  error_bool = FALSE
  
  if(datasets$Description.of.the.dataset[dataset] == ""){# where there is no abstract
    error <- data.frame(
      n = dataset,
      uuid = datasets$uuid[dataset],
      title = datasets$Title.Identifier..if.no.DOI.available.[dataset],
      error = 'missing abstract',
      contact = datasets$Producer[dataset],
      error_level = 'error'
    )
    error_bool = TRUE
    csv_error <- rbind(csv_error, error)
  }
  if (datasets$Producer[dataset] %in% c("mundialis")){# we harvest them
    error <- data.frame(
      n = dataset,
      uuid = datasets$uuid[dataset],
      title = datasets$Title.Identifier..if.no.DOI.available.[dataset],
      error = 'already harvested',
      contact = datasets$Producer[dataset],
      error_level = 'error'
    )
    error_bool = TRUE
    csv_error <- rbind(csv_error, error)
  }
  if (datasets$Link..html..to.an.image.logo.figure.representing.the.database[dataset] == ""){
    error <- data.frame(
      n = dataset,
      uuid = datasets$uuid[dataset],
      title = datasets$Title.Identifier..if.no.DOI.available.[dataset],
      error = 'missing thumbnail',
      contact = datasets$Producer[dataset],
      error_level = 'warning'
    )
    csv_error <- rbind(csv_error, error)
    if (datasets$Producer[dataset] == "ERGO"){
      datasets$Link..html..to.an.image.logo.figure.representing.the.database[dataset] = "https://gitlab.irstea.fr/umr-tetis/mood/geonetwork-insertion/-/raw/master/readme.img/ergo.png"
    }
  }
  
  
  if(error_bool == FALSE){ #skip when error
    metadata_id <- datasets$uuid[dataset]
    
    ##Création métadonnée
    md = ISOMetadata$new()
    metadata_id=paste(metadata_id)
    md$setFileIdentifier(metadata_id)
    md$setCharacterSet("utf8")
    md$setMetadataStandardName("ISO 19115:2003/19139")
    md$setLanguage("eng")
    md$setDateStamp(Sys.time())
    # md$setHierarchyLevel("dataset")
    md$setHierarchyLevel(paste(datasets$dataset.or.software[dataset]))
    
    ##Creation identification
    ident <- ISODataIdentification$new()
    ident$setAbstract(paste(datasets$Description.of.the.dataset[dataset]))
    ident$setLanguage("eng")
    ident$addTopicCategory("health")

    ## keywords
    ### General Keywords
    dynamic_keywords <- ISOKeywords$new()
    for (kw in unlist(strsplit(paste(datasets$Database.Key.words[dataset]), ", "))){
      dynamic_keywords$addKeyword(kw)
    }
    for (kw in unlist(strsplit(paste(datasets$Usefull.for.which.diseases[dataset]), ", "))){
      dynamic_keywords$addKeyword(kw)
    }
    ident$addKeywords(dynamic_keywords)
  
    # add links data access
    distrib <- ISODistribution$new()
    dto <- ISODigitalTransferOptions$new()
    ## data access
    link <- paste0(datasets$Give.the.DOI..or.URL..to.access.the.dataset.in.the.data.repository[dataset])
    newURL <- ISOOnlineResource$new()
    newURL$setName("Access to data")
    newURL$setLinkage(link)
    newURL$setProtocol("WWW:LINK-1.0-http--link")
    dto$addOnlineResource(newURL)
    ## code 
    link <- paste0(datasets$Code.available..link.[dataset])
    newURL <- ISOOnlineResource$new()
    newURL$setName("Access to code")
    newURL$setLinkage(link)
    newURL$setProtocol("WWW:LINK-1.0-http--link")
    dto$addOnlineResource(newURL)
    ## if publication
    link <- paste0(datasets$If.the.dataset.is.linked.to.a.publication..specify.the.DOI.of.the.publication[dataset])
    newURL <- ISOOnlineResource$new()
    newURL$setName("Access to publication")
    newURL$setLinkage(link)
    newURL$setProtocol("WWW:LINK-1.0-http--link")
    dto$addOnlineResource(newURL)

    
    distrib$setDigitalTransferOptions(dto)
    md$setDistributionInfo(distrib)
  
    ## Producer
    rp <- ISOResponsibleParty$new()
    producer = paste0(datasets$Producer[dataset])
    rp$setOrganisationName(producer)
    rp$setRole("principalInvestigator")
    ident$addPointOfContact(rp)
    
    #adding legal constraint(s)
    if(nchar(as.character(datasets$Licence[dataset])) !=0) {
      lc <- ISOLegalConstraints$new()
      lc$addUseLimitation(datasets$Licence[dataset])
      ident$setResourceConstraints(lc)
    }
    # Titre et identification
    ct <- ISOCitation$new()
    ct$setTitle(paste(datasets$Title.Identifier..if.no.DOI.available.[dataset]))
    isoid=ISOMetaIdentifier$new(code = datasets$uuid[dataset])
    ct$setIdentifier(isoid)
    ident$setCitation(ct)
    ## thumbnail
    for(thumbnail in unlist(strsplit(paste(datasets$Link..html..to.an.image.logo.figure.representing.the.database[dataset]), ", "))){
      go <- ISOBrowseGraphic$new(
        fileName = thumbnail,
        fileDescription = "thumbnail",
        fileType = "image/png"
      )
      ident$addGraphicOverview(go)
    }
    md$addIdentificationInfo(ident)
  
    # Conversion to iso19139 and saving the XML file
    md$encode(inspire = FALSE)
    nom_fichier = str_replace_all(datasets$Title.Identifier..if.no.DOI.available.[dataset], " ", "_")
    nom_fichier = str_replace_all(nom_fichier, "/", "_") 
    nom_fichier = paste(nom_fichier, "xml", sep=".") 
    chemin_fichier = paste("xml_generated", nom_fichier, sep="/")
    md$save(chemin_fichier)
  
    # require(XML)
    # filenames = list.files("xml_generated", pattern="*.xml") 
    # for (file in filenames) {# nous parcourons l'ensemble des fichiers xml
    #   chemin_fichier = paste("xml_generated", file, sep="/")
    #   xml = xmlParse(chemin_fichier)
    #   md = ISOMetadata$new(xml = xml) # création de l'objet ISOMetadata
    #   created = gn$insertMetadata( # insertion dans GeoNetwork
    #     xml = md$encode(),
    #     group = "1",
    #   )
    # }
  }
  
}
current_datetime <- format(Sys.time(), "%Y%m%d_%H%M%S")
filename <- paste0("logs/csv_error_", current_datetime, ".csv")
write.csv(csv_error, filename, row.names = FALSE)