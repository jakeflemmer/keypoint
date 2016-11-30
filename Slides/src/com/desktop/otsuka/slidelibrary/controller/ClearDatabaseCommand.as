package com.desktop.otsuka.slidelibrary.controller
{
	import com.desktop.otsuka.slidelibrary.model.DatabaseModel;
	import com.desktop.otsuka.slidelibrary.view.LoginPanel;
	
	import flash.data.SQLConnection;
	import flash.data.SQLStatement;
	import flash.errors.IOError;
	import flash.errors.SQLError;
	import flash.filesystem.File;
	
	import mx.controls.Alert;
	
	public class ClearDatabaseCommand
	{
		public function ClearDatabaseCommand()
		{
		}
		
		public function clearDatabase():void{
			
			if ( ! LoginPanel.MAC_BUILD )
			{
				if( DatabaseModel.getInstance().databaseAlreadyExists ) { 
					deleteDatabaseFolder();
				}
			}
			
			dropDatabase(DatabaseModel.getInstance().systemSQLConnection);
			dropDatabase(DatabaseModel.getInstance().customSQLConnection);
		}
		
		public function dropOldSlidesAloneTableForMigrationToV3():void{
			
			var dropTablesStatement:SQLStatement = new SQLStatement();
			dropTablesStatement.sqlConnection = DatabaseModel.getInstance().systemSQLConnection;
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'slides_alone'";
			try { 
				dropTablesStatement.execute();
				//trace(" Slides alone table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}
		}
		
		
		private function deleteDatabaseFolder():void
		{
			try { 
				if( DatabaseModel.getInstance().dbFolder.exists )
				{
					DatabaseModel.getInstance().dbFolder.deleteDirectory(true); //easy.
				}
			}
			catch( error:IOError ) { 
				try { 
					for each( var thing:File in DatabaseModel.getInstance().dbFolder.getDirectoryListing() ) { 
						if( thing.isDirectory ) thing.deleteDirectory(true);
						else thing.deleteFile();
					}
				}
				catch( error:IOError ) { 
					//throw new Error("error"); TODO hmm.. what is really going on here?
					//dropDatabase( dbModel.systemSQLConnection ); //can't believe i wrote all of this..
					//dropDatabase( dbModel.customSQLConnection );
				}
			}
			
		}
		
		private function dropDatabase( sqlConnection:SQLConnection ):void
		{
			if ( ! DatabaseModel.getInstance().mustDropOldTables ) return;
			
			var dropTablesStatement:SQLStatement = new SQLStatement();
			dropTablesStatement.sqlConnection = sqlConnection; //dbModel.systemSQLConnection;
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'users'";
			try { 
				dropTablesStatement.execute();
				//trace(" Users table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'slides_alone'";
			try { 
				dropTablesStatement.execute();
				//trace(" Slides alone table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'bundles'";
			try { 
				dropTablesStatement.execute();
				//trace(" Bundles table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'slides'";
			try { 
				dropTablesStatement.execute();
				//trace(" Slides table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'sections'";
			try { 
				dropTablesStatement.execute();
				//trace(" Sections table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'presentations'";
			try { 
				dropTablesStatement.execute();
				//trace(" Presentations table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'optional_deck_ids_relation_to_presentation_ids'";
			try { 
				dropTablesStatement.execute();
				//trace("optional_decks table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}			
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'optional_decks'";
			try { 
				dropTablesStatement.execute();
				//trace("optional_decks table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}			
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'optional_sections'";
			try { 
				dropTablesStatement.execute();
				//trace("optional_sections table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}	
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'optional_slides'";
			try { 
				dropTablesStatement.execute();
				//trace("optional_slides table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}	
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'title_slide'";
			try { 
				dropTablesStatement.execute();
				//trace("title_slide table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}	
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'resources'";
			try { 
				dropTablesStatement.execute();
				trace("resources table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}	
			
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'external_apps'";
			try { 
				dropTablesStatement.execute();
				trace("external_apps table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}	
			
			// V6
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'either_or_combinations'";
			try { 
				dropTablesStatement.execute();
				trace("either_or_combinations table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}	
			
			trace("All old datatable have been dropped");
		}
		
		public static function dropExternalAppsTable(){
			var dropTablesStatement:SQLStatement = new SQLStatement();
			dropTablesStatement.sqlConnection = DatabaseModel.getInstance().systemSQLConnection; 
			dropTablesStatement.text = "DROP TABLE IF EXISTS 'external_apps'";
			try { 
				dropTablesStatement.execute();
				trace("external_apps table DROPPED successfully!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + error.message);
				trace(" Details: " + error.details);
				//Alert.show("Error : " + error.details);
			}	
		}
	}// close class
}

// close package