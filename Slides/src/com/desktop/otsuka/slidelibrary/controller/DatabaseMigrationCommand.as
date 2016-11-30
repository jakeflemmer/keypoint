package com.desktop.otsuka.slidelibrary.controller
{
	import com.desktop.otsuka.slidelibrary.model.DatabaseModel;
	
	import flash.data.SQLColumnSchema;
	import flash.data.SQLConnection;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;
	import flash.errors.SQLError;
	
	import mx.controls.Alert;
	import mx.formatters.DateFormatter;
	import mx.utils.UIDUtil;

	public class DatabaseMigrationCommand
	{
		/*
			The idea of this class is that starting with V6 we want to alter our datatables in a more organized coherent way.
		
			We determine if we have the latest verion of datatables by testing at startup if we have the correct number of tables + columns etc...
		
			We then upgrade everything at once !
		
			For new users we create V6 data tables at the giddyup
		
		
		*/
		public function DatabaseMigrationCommand()
		{
			
		}
		
		public function handleDataBaseMigration():void{
			
			
			//DANGER
			//return;
			
			// check if it is a V6 database
			var isV6DB:Boolean = databaseIsV6DataBase();
			if ( ! isV6DB )
			{
				migrateToV6Database();
			}
		}
		
		private function databaseIsV6DataBase():Boolean{
			
			// if it has "isPushed" in it's custom presentations tables then it's a V6 DB
			dbModel.customSQLConnection.loadSchema( SQLTableSchema , "presentations" );
			var schemaResult:SQLSchemaResult = dbModel.customSQLConnection.getSchemaResult();
			
			var tableSchema:SQLTableSchema = schemaResult.tables[0];
			var columnsArray:Array = tableSchema.columns;
			
			for ( var i:uint = 0 ; i < columnsArray.length; i++ )
			{
				var column:SQLColumnSchema = columnsArray[i];
				if ( column.name == "is_pushed" )
				{					
					return true;
				}
			} 
			return false;			
		}
		
		private function migrateToV6Database():void{
			// add three columns
				// presentations
					// is_pushed
					// guid
					// is_deleted
					// user_last_saved
				// slides
					// section_slide_id
				// title slide
					// custom_timestamp
			
			//------------------------- is_pushed
			var addColumnStatement1:SQLStatement = new SQLStatement();
			addColumnStatement1.sqlConnection = dbModel.customSQLConnection;
			
			addColumnStatement1.text = "ALTER TABLE presentations ADD COLUMN is_pushed BOOLEAN ";
			
			try { 
				addColumnStatement1.execute();
			}
			catch( error:SQLError ) { 
				trace(" Error: " + addColumnStatement1.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			//--------------------------- guid
			var addColumnStatement2:SQLStatement = new SQLStatement();
			addColumnStatement2.sqlConnection = dbModel.customSQLConnection;
			
			addColumnStatement2.text = "ALTER TABLE presentations ADD COLUMN guid TEXT ";
			
			try { 
				addColumnStatement2.execute();
			}
			catch( error:SQLError ) { 
				trace(" Error: " + addColumnStatement2.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			//--------------------------- is_deleted
			var addColumnStatement3:SQLStatement = new SQLStatement();
			addColumnStatement3.sqlConnection = dbModel.customSQLConnection;
			
			addColumnStatement3.text = "ALTER TABLE presentations ADD COLUMN is_deleted BOOLEAN ";
			
			try { 
				addColumnStatement3.execute();
			}
			catch( error:SQLError ) { 
				trace(" Error: " + addColumnStatement3.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			//--------------------------- user_last_saved
			var addColumnStatement4:SQLStatement = new SQLStatement();
			addColumnStatement4.sqlConnection = dbModel.customSQLConnection;
			
			addColumnStatement4.text = "ALTER TABLE presentations ADD COLUMN user_last_saved TEXT ";
			
			try { 
				addColumnStatement4.execute();
			}
			catch( error:SQLError ) { 
				trace(" Error: " + addColumnStatement4.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			
			//------------------------------ section_slide_id
			var addColumnStatement5:SQLStatement = new SQLStatement();
			addColumnStatement5.sqlConnection = dbModel.customSQLConnection;
			
			addColumnStatement5.text = "ALTER TABLE slides ADD COLUMN section_slide_id INTEGER ";
			
			try { 
				addColumnStatement5.execute();
			}
			catch( error:SQLError ) { 
				trace(" Error: " + addColumnStatement5.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			//------------------------------ chosen_timestamp
			var addColumnStatement6:SQLStatement = new SQLStatement();
			addColumnStatement6.sqlConnection = dbModel.customSQLConnection;
			
			addColumnStatement6.text = "ALTER TABLE title_slide ADD COLUMN chosen_timestamp INTEGER ";
			
			try { 
				addColumnStatement6.execute();
			}
			catch( error:SQLError ) { 
				trace(" Error: " + addColumnStatement6.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			//add either_or_combinations table
			
			var createTableStatement:SQLStatement = new SQLStatement();
			createTableStatement.sqlConnection = dbModel.systemSQLConnection;
			
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
			
			
			// chosen_timestamp
			
			// add columns to custom presentations table
				// for each row in the table
					// populate new columns
			
			// now get all the rows
			// populate the new fields on each row
			var allRows:Array = dbModel.getAll(dbModel.customSQLConnection, "presentations");
			if ( allRows && allRows.length > 0 )
			{
				for ( var i:uint = 0; i < allRows.length; i ++)
				{
					// presentations
					// is_pushed
					// guid
					// is_deleted
					// user_last_saved
					var presentation:Object = allRows[i];
					presentation.is_pushed = false;
					presentation.guid = UIDUtil.createUID().toString();
					presentation.is_deleted = false;
					
					var timestamp:Number = (new Date().time) / 1000;
					presentation.user_last_saved = timestamp;
										
//					take the old created date as a time string and get a unix timestamp from it
					
					var dateString:String = presentation.date_created;
					var year:Number = ( presentation.date_created as String).split("-")[0];
					var month:Number = ( presentation.date_created as String).split("-")[1] - 1;
					var day:Number = ( presentation.date_created as String).split("-")[2];
					var date:Date = new Date(year,month,day);
										
					//dateFormatter.formatString = "YYYY-MM-DD";									
					
					//V6 we need more than just the date we need the time as well
					var time:Number = date.time;
					//presentationObject.date_created = dateString;
					presentation.date_created = time.toString();
					
					dbModel.insertASinglePresentationObjectIntoPresentationsTable(presentation , dbModel.customSQLConnection);
					
				}

			}
						
		}
		
		
		
		
		//////=====================================
		//Getters and Setters
		//=-========================================
		private function get dbModel():DatabaseModel{
			return DatabaseModel.getInstance();
		}
		
	}
}