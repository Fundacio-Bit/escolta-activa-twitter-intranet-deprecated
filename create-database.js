/* eslint-disable no-undef */

/*
 * Script que se encarga de poblar la base de datos  
 *
 * _brands:
 *  {
        "project" : project name,
        "brand_name" : brand to search,
        "keywords" : list of keywords refenced to the brand,
        "blacklist" : list words excluded
    }
    _contexts:
    {
        "context_name" : context name defined in
        environment variable,
        "log_dir" : path to log directory,
        "output_base_dir" : path to output directory
    }

    _stopwords:
    {
        list of stopwords
    }

    dictionary_terms:
    {
        "category" : category name,
        "status" : deprecated,
        "_canonical_name" : canonical name,
        "brand" : brand_name,
        "created_by" : author,
        "creation_date" : date with format "yyy-mm-dd",
        "alias" : string with alias separated by ","
        "last_modified" : date with format "yyy-mm-dd"
    }

    dictionary_influencers:
    {

    }

    twitter_daily_basic_counts_<"year">
    twitter_daily_advanced_counts_<"year">
    twitter_monthly_viral_tweets_<"year">_<"brand">
    twitter_monthly_json_reports_<"year">_<"brand">
*/

print("STARTING SCRIPT");

conn = new Mongo("localhost");

db = conn.getDB("escolta_activa_db");

db.dropDatabase();

db.createCollection("brands");

print("***********creating brands*********");


brand1 = {
	project: "escolta-activa", 
	brand_name: "mallorca", 
	keywords: [], 
	blacklist: []
};

print("***********creating _contexts*********");

db.createCollection("contexts");

context1 = {
	context_name:"default", 
	log_dir: "C:/Users/Elena/Proyectos/EscuchaActiva/files/log", 
	output_base_dir : "C:/Users/Elena/Proyectos/EscuchaActiva/files/output/"
};

print("***********saving brands*********");
db.brands.save(brand1)


print("***********saving contexts*********");
db.contexts.save(context1)

db.brands.renameCollection("_brands")
db.contexts.renameCollection("_contexts")
