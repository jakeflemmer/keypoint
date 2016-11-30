package com.desktop.otsuka.slidelibrary.controller
{
	import com.desktop.otsuka.slidelibrary.model.DatabaseModel;
	import com.desktop.otsuka.slidelibrary.view.LoginPanel;
	
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	
	
	public class CreateV6DatabaseCommand
	{
		/*
			This class is obviously like it's doppelganger but for V6 databases
		
			We don't want to clean up and delete / improve / reorganize.
		
			We just want to add.
		
		*/
		
		public function CreateV6DatabaseCommand()
		{
		
	
			
		}
		public function createTheDataBase():void{
			
			if ( LoginPanel.MAC_BUILD)
			{
				dbModel.resolveDatabasePaths(); //open the SQL connection
				setTimeout(function(o:Object=null):void{
					createSystemDatabase( dbModel.systemSQLConnection );
					createSystemDatabase( dbModel.customSQLConnection );
				},4000);
			}
			else
			{
				if( ! dbModel.dbFolder.exists ) { 
					trace("create database command dbfolder does NOT exist!");
					dbModel.resolveDatabasePaths();
				}else{
					trace("create database command dbfolder does exist!");
				}
				createSystemDatabase( dbModel.systemSQLConnection );
				createSystemDatabase( dbModel.customSQLConnection ); //duplicate for custom presentations
			}
		}
		
		
		public function createNewSlidesAloneTableForV3():void{
			
			var createTableStatement:SQLStatement = new SQLStatement();
			createTableStatement.sqlConnection = DatabaseModel.getInstance().systemSQLConnection;
			
			
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS slides_alone (" + 
				" slide_id INTEGER PRIMARY KEY NOT NULL," + 
				" notes TEXT DEFAULT ''," + 
				" thumbnail TEXT," +
				" printable_pdf TEXT, " +
				" swf TEXT, " +
				" flv TEXT, " +
				" is_animated BOOLEAN " + 
				" )";
			
			try { 
				createTableStatement.execute();
				//trace(" Slides Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
		}
		
		// TODO optional_slides dont have section_slide_id yet
		
		/*
		TABLES
		=========================================================================
		
		ok			users
		====================================================================================================
		//user_id    
		user_name    
		//user_password 	
		user_hash 	
		last_updated 	
		all_files_have_been_downloaded
		
		|||||| ADDING FOR V6  |||||||
		
		has_worked_offline
		
		
		ok			slides_alone
		===================================
		slide_id 	
		notes
		thumbnail
		printable_pdf
		swf
		flv
		is_animated
		
		
		
		ok			bundles
		====================================================
		is_adjacent
		bundle_id 
		is_sequential
		keep_whole  **
		mandatory   **
		size 
		
		
		
		ok			presentations 
		===================================================================
		(custom_presentation_id) 		
		(custom_title)
		
		brand_id 	
		date_created 	
		presentation_name     	   
		presentation_id		 
		is_locked 			 
		* optional_decks *
		printable_pdf
		sequence_locked
		*sections*
		
		
		ok			sections
		====================================================================================================================================
		(custom_section_id)
		(custom_section_in_presentation_id)
		
		section_id  	 
		section_name	 
		sequence 	 
				
		presentation_id		 
		is_sequential ??
		*slides*
		
		
		CORE			slides		-- change to section_slides
		=====================================================================================================================================
		bundle_id
		bundle_position
		is_locked		  -- not used anywhere
		is_mandatory	
		section_slide_id		
		sequence 
		slide_id  
		
		section_id 
		presentation_id 
		
		(unwanted)		
		
		||||| ADDING TO V6   ||||||||||
		
		last_updated
		
		
		CUSTOM slides
		=====================================================================================================================================
		" sec_slide_id_plus_cust_pres_id INTEGER PRIMARY KEY NOT NULL," +
		" slide_id INTEGER NOT NULL," +	 			
		" section_id INTEGER," + 
		" presentation_id INTEGER," + 
		" bundle_id INTEGER DEFAULT NULL," + 
		" bundle_position INTEGER DEFAULT NULL," + 
		" sequence INTEGER," + 
		" is_locked BOOLEAN DEFAULT 0," + 
		" is_mandatory BOOLEAN DEFAULT 0," + 
		" unwanted BOOLEAN DEFAULT 0" +		
		" optional_deck_id " +
		" customSequence INTEGER DEFAULT NULL"
		
		||||| ADDING TO V6   ||||||||||
		
		"section_slide_id "
		"uuid"
		"isPushed"
		"isDeleted"
		"user_last_saved"
		
		
		
		optional_deck_ids_relation_to_presentation_ids
		=====================================================================================================
		core_optional_connection_id				-- unique number from Malka
		optional_deck_id
		presentation_id
		
		optional_decks
		=====================================================================================================
		optional_deck_id
		deck_name
		
		
		optional_sections
		=====================================================================================================
		section_id	 
		optional_deck_id 
		section_name
		sequence
				
		optional_slides
		====================================================================================================
		
		slide_id  
		section_id 
		optional_deck_id 
		section_slide_id
		bundle_id
		bundle_position
		sequence	  
		unwanted	
		
		
		title_slide
		======================================================================================================
		custom_presentation_id
		date_string
		date_x
		date_y
		date_size
		date_color
		title_string
		title_x
		title_y
		title_color
		title_size
		chosen_timestamp
		
		*/
		
		private function createNewDatabase(sqlConnection:SQLConnection):void{
			
		}
		private function createSystemDatabase(sqlConnection:SQLConnection):void
		{
			var createTableStatement:SQLStatement = new SQLStatement();
			createTableStatement.sqlConnection = sqlConnection;
			
			/* NOTE !!!!
			
				THIS USERS TABLE IS ALSO CREATED IN THE DATABASEMODEL CLASS IN THE insertUserIntoUsersTableWhenAllDownloadsAreComplete FUNCTION !!
			
			*/
			
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS users (" + 
				//" user_id INTEGER PRIMARY KEY AUTOINCREMENT," + 
				" user_name TEXT," + 
				//" user_password TEXT," + 
				" user_hash TEXT," + 
				" last_updated TEXT," + 
				" hasExcel BOOLEAN DEFAULT 0," +
				" hasNnpe BOOLEAN DEFAULT 0," +
				" all_files_have_been_downloaded BOOLEAN DEFAULT 0," + 
				" has_worked_offline BOOLEAN DEFAULT 0" +
				" )";
			
			try { 
				createTableStatement.execute();
				//trace(" users Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS slides_alone (" + 
				" slide_id INTEGER PRIMARY KEY NOT NULL," + 
				" notes TEXT DEFAULT ''," + 
				" thumbnail TEXT," +
				" printable_pdf TEXT, " +
				" swf TEXT, " +
				" flv TEXT, " +
				" is_animated BOOLEAN " + 
				" )";
			
			try { 
				createTableStatement.execute();
				//trace(" Slides Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS bundles (" + 
				" bundle_id INTEGER PRIMARY KEY NOT NULL, " + 
				" size INTEGER, " + 
				" keep_whole BOOLEAN, " + 
				" is_sequential BOOLEAN, " + 
				" is_adjacent BOOLEAN, " + 
				" mandatory BOOLEAN " + 
				" )";
			
			try { 
				createTableStatement.execute();
				//trace(" Bundles Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			
			
			
			
			
			
			// PRESENTATIONS
			
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS presentations (" + 
				((sqlConnection == dbModel.customSQLConnection) ? 
					//" custom_presentation_id INTEGER PRIMARY KEY AUTOINCREMENT, presentation_id INTEGER, " : 
					" custom_presentation_id INTEGER, presentation_id INTEGER, " :
					" presentation_id INTEGER PRIMARY KEY NOT NULL," ) +				
				" presentation_name TEXT," + 
				" date_created TEXT," + 
				" brand_id INTEGER," +				
				" is_locked BOOLEAN DEFAULT '0'," + 
				" custom_title TEXT," +
				" printable_pdf TEXT," +
				" sequence_locked BOOLEAN," +
				" sectionId INTEGER, " +
				" resources_title TEXT, " +
				" resources_order TEXT" + 			
				((sqlConnection == dbModel.customSQLConnection) ? 
					", is_pushed BOOLEAN, guid TEXT PRIMARY KEY, is_deleted BOOLEAN, user_last_saved TEXT " :
					"" ) +
				" )";
			
			// presentations
			// is_pushed
			// guid
			// is_deleted
			// user_last_saved
			
			try { 
				createTableStatement.execute();
				//trace(" CUSTOM Presentations Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			
			// SECTIONS
			
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS sections (" + 
				((sqlConnection == dbModel.customSQLConnection) ? 
					" custom_section_id INTEGER PRIMARY KEY AUTOINCREMENT, section_id INTEGER," : 
					" section_id INTEGER PRIMARY KEY NOT NULL," ) + 
				" presentation_id INTEGER NOT NULL," + 
				" section_name TEXT," + 
				" sequence INTEGER," + 
				" is_sequential BOOLEAN DEFAULT 0" + 
				" )";
			
			try { 
				createTableStatement.execute();
				//trace(" Sections In Presentations Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			
			
			//			var firstLine:String = "";
			//			if (sqlConnection == dbModel.customSQLConnection) 
			//			{
			//				firstLine = " custom_slide_id INTEGER PRIMARY KEY AUTOINCREMENT, slide_id INTEGER,"; 
			//			}
			//			else
			//			{
			//				firstLine = " slide_id INTEGER PRIMARY KEY NOT NULL,";				
			//			}
			
			if (sqlConnection == dbModel.systemSQLConnection) 
			{
				createTableStatement.text = "CREATE TABLE IF NOT EXISTS slides (" +
					" section_slide_id INTEGER PRIMARY KEY NOT NULL," +
					" slide_id INTEGER NOT NULL," +	 			
					" section_id INTEGER," + 
					" presentation_id INTEGER," + 
					" bundle_id INTEGER DEFAULT NULL," + 
					" bundle_position INTEGER DEFAULT NULL," + 
					" sequence INTEGER," + 
					" is_locked BOOLEAN DEFAULT 0," + 
					" is_mandatory BOOLEAN DEFAULT 0," + 
					" unwanted BOOLEAN DEFAULT 0" +				
					" )";
				
				try { 
					createTableStatement.execute();
					//trace(" slides Table CREATED successfully!");
				}
				catch( error:SQLError ) { 
					trace(" Error: " + createTableStatement.text);
					trace(" Details: " + error.details);
					Alert.show("Error : " + error.details);
				}
			}
			else
			{
				createTableStatement.text = "CREATE TABLE IF NOT EXISTS slides (" +
					" sec_slide_id_plus_cust_pres_id INTEGER PRIMARY KEY NOT NULL," +
					" slide_id INTEGER NOT NULL," +	 			
					" section_id INTEGER," + 
					" presentation_id INTEGER," + 
					" bundle_id INTEGER DEFAULT NULL," + 
					" bundle_position INTEGER DEFAULT NULL," + 
					" sequence INTEGER," + 
					" is_locked BOOLEAN DEFAULT 0," + 
					" is_mandatory BOOLEAN DEFAULT 0," + 
					" unwanted BOOLEAN DEFAULT 0," +	
					" optional_deck_id INTEGER," +
					" customSequence INTEGER DEFAULT NULL, " +
					" section_slide_id INTEGER " + 
					" )";
				
				try { 
					createTableStatement.execute();
					//trace(" slides Table CREATED successfully!");
				}
				catch( error:SQLError ) { 
					trace(" Error: " + createTableStatement.text);
					trace(" Details: " + error.details);
					Alert.show("Error : " + error.details);
				}
			}
			
			
			//optional_deck_ids_relation_to_presentation_ids
			//=====================================================================================================
			//	core_optional_connection_id				-- unique number from Malka
			//	optional_deck_id
			//	presentation_id
			
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS optional_deck_ids_relation_to_presentation_ids (" +
				" core_optional_connection_id INTEGER PRIMARY KEY NOT NULL," + 
				" optional_deck_id INTEGER NOT NULL," +	 			
				" presentation_id TEXT" + 
				" )";
			
			try { 
				createTableStatement.execute();
				//trace(" optional_decks Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS optional_decks (" +
				" optional_deck_id INTEGER PRIMARY KEY NOT NULL," +	 			
				" deck_name TEXT" + 
				" )";
			
			try { 
				createTableStatement.execute();
				//trace(" optional_decks Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			
			
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS optional_sections (" +
				" section_id INTEGER PRIMARY KEY NOT NULL," +	 
				" optional_deck_id INTEGER," + 
				" section_name TEXT," + 
				" sequence INTEGER" + 
				" )";
			
			try { 
				createTableStatement.execute();
				//trace(" optional_sections Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS optional_slides (" +
				" slide_id INTEGER," +	 
				" section_id INTEGER," +
				" optional_deck_id INTEGER," + 
				" section_slide_id INTEGER PRIMARY KEY NOT NULL," + 
				" bundle_id INTEGER," + 
				" bundle_position INTEGER," + 
				" sequence INTEGER," + 
				" unwanted BOOLEAN" + 
				" )";
			
			try { 
				createTableStatement.execute();
				//trace(" optional_slides Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS title_slide (" +
				" custom_presentation_id INTEGER PRIMARY KEY NOT NULL, " +
				" date_string TEXT," +	 
				" date_x INTEGER," +
				" date_y INTEGER," +
				" date_size INTEGER," +
				" date_color INTEGER," +
				" title_string TEXT," +
				" title_x INTEGER," +
				" title_y INTEGER," +
				" title_color INTEGER," +
				" title_size INTEGER," +
				" chosen_timestamp INTEGER " +
				" )";
			
			try { 
				createTableStatement.execute();
				//trace(" title_slide Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}			
			
			// V5.0 resources table
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS resources (" +
				" id INTEGER PRIMARY KEY NOT NULL, " +
				" brand_id INTEGER," +	
				" brand_name TEXT," +	
				" deck_id INTEGER," +	
				" deck_name TEXT," +	
				" url TEXT," +	 
				" html_title TEXT," +
				" stripped_title TEXT," +
				" resources_title TEXT," +		
				" refNumber INTEGER" +
				" )";
			
			try { 
				createTableStatement.execute();
				//trace(" resources Table CREATED successfully!");  
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}			
			
			// V5.1 external_apps table
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS external_apps (" +
				" app_name TEXT PRIMARY KEY" +	
				" )";
			
			try { 
				createTableStatement.execute();
				trace(" new external_apps Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}		
			
			
			// V6.0 either_or_combinations table
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS either_or_combinations (" +
				" presentation_id INTEGER, " +
				" object_one_content_type TEXT," +	
				" object_one_object_id INTEGER," +	
				" object_two_content_type TEXT," +	
				" object_two_object_id INTEGER," +		
				" required BOOLEAN" +
				" )";
			
			try { 
				createTableStatement.execute();
				//trace(" resources Table CREATED successfully!");  
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}			
			
			
			trace("new datatables CREATED");			
		}
		
		public static function checkIfResourcesDataTableExistsAndCreateItIfItDoesnt():void{
			var createTableStatement:SQLStatement = new SQLStatement();
			createTableStatement.sqlConnection = dbModel.systemSQLConnection;
			
			// V5.0 resources table
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS resources (" +
				" id INTEGER PRIMARY KEY NOT NULL, " +
				" brand_id INTEGER," +	
				" brand_name TEXT," +	
				" deck_id INTEGER," +	
				" deck_name TEXT," +	
				" url TEXT," +	 
				" html_title TEXT," +
				" stripped_title TEXT," +
				" resources_title TEXT," +
				" refNumber INTEGER" +
				" )";
			
			try { 
				createTableStatement.execute();
				trace(" new resources Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}		
			
		}
		
		public static function createExternalAppsDataTableIfItDoesntAlreadyExist():void{
			var createTableStatement:SQLStatement = new SQLStatement();
			createTableStatement.sqlConnection = dbModel.systemSQLConnection;
			
			// V5.1 external_apps table
			createTableStatement.text = "CREATE TABLE IF NOT EXISTS external_apps (" +
				" app_name TEXT PRIMARY KEY" +	
				" )";
			
			try { 
				createTableStatement.execute();
				trace(" new external_apps Table CREATED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}		
		}
		
		public static function get dbModel():DatabaseModel{
			return DatabaseModel.getInstance();
		}
	}
}

