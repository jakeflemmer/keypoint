package com.desktop.otsuka.slidelibrary.model
{
	import com.desktop.otsuka.slidelibrary.controller.SlidesUtilities;
	import com.desktop.otsuka.slidelibrary.view.LoginPanel;
	
	import flash.data.SQLColumnSchema;
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLSchemaResult;
	import flash.data.SQLStatement;
	import flash.data.SQLTableSchema;
	import flash.errors.SQLError;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	import mx.formatters.DateFormatter;
	import mx.utils.UIDUtil;
	
	public class DatabaseModel extends EventDispatcher
	{
		public var dbFolder:File;
		public var systemDBFile:File;
		public var systemSQLConnection:SQLConnection;
		public var customDBFile:File;
		public var customSQLConnection:SQLConnection;
		public var databaseAlreadyExists:Boolean;
		public var mustDropOldTables:Boolean = false;
		
		public var updatedPDFMastersMap:Object = new Object();
		public var updatedPDFSlidesMap:Object = new Object();
		
		public var mustUpdateResourcePDFsMap:Object = new Object();
		
		public var logIinTimeUnixTimeStamp:String = "";
		
		public var dateFormatter:DateFormatter;
		
		public var slidesInserted:uint = 0;
		
		public static const MESSAGE_3:String = "Checking credentials...";	// NOT USED IN DESKTOP
		public static const MESSAGE_5a:String = "Retrieving data from server"; // NOT USED IN DESKTOP
		public static const MESSAGE_5b:String = "Adding slides to model";   // NOT USED IN DESKTOP
		public static const MESSAGE_5c:String = "Adding presentations to model";   // NOT USED IN DESKTOP
		public static const MESSAGE_6:String = "There was an error while saving the data to the system:Please Log In again";   // NOT USED IN DESKTOP
		public static const MESSAGE_7b:String = "Updating data model";   // NOT USED IN DESKTOP
		public static const MESSAGE_7c:String = "Deleting data from model";   // NOT USED IN DESKTOP
		public static const MESSAGE_7d:String = "Creating new data";   // NOT USED IN DESKTOP
		public static const MESSAGE_8:String = "There was an error while saving the data to the system: please log in again";   // NOT USED IN DESKTOP
		public static const MESSAGE_9:String = "There appears to be no data in the system: please connect to the Internet and log in with your username/password";  // NOT USED IN DESKTOP
		public static const MESSAGE_13:String = "Checking server for updates"; // NOT USED IN DESKTOP
		public static const MESSAGE_14:String = "There was an error while saving the data to the system: you must update to continue further. Press YES to update, NO to logout";  // NOT USED IN DESKTOP
		public static const MESSAGE_38:String = "Applying updates data";  // NOT USED IN DESKTOP		
		public static const MESSAGE_22:String = "There are no slides presently being displayed in this customization";  // NOT USED IN DESKTOP
		public static const MESSAGE_23:String = "Due to user privileges, you are not able to customize this presentation";  // NOT USED IN DESKTOP
		public static const MESSAGE_24:String = "You must connect device to external display before being able to present";  // NOT USED IN DESKTOP
		public static const MESSAGE_25:String = "To customize a deck, there needs to be a title for the presentation";  // NOT USED IN DESKTOP		
		public static const MESSAGE_31:String = "To move this slide, you must move the whole bundle by holding 2 fingers on the slide. Display message again?"; // NOT USED IN DESKTOP
		public static const MESSAGE_36:String = "Adding slides to model";  // NOT USED IN DESKTOP
		
		
		public static const MESSAGE_32:String = "All slides within this bundle must be presented. To remove this slide, you must remove all slides within the bundle. Remove all slides within this bundle?";  // updated 6/18 4:45 pm USED		
		public static const MESSAGE_18:String = "Customizing a deck requires a title for the presentation."; // USED text update 6/17/13
		public static const MESSAGE_7a:String = "Retrieving data from server";  // USED
		public static const MESSAGE_33:String = "Copying custom presentation";  // USED
		public static const MESSAGE_34:String = "Updating slide library";  // USED
		public static const MESSAGE_26:String = "Presentation titles cannot exceed 55 characters";  // USED		
		public static const MESSAGE_30:String = "The changes you have made have not been saved. Would you like to save them?";  // USED
		public static const MESSAGE_35:String = "Downloading slide library";  // USED
		public static const MESSAGE_37:String = "Checking user credentials";  // USED
		public static const MESSAGE_39:String = "Due to user privileges, you are not able to customize this presentation";  // updated 6/18 4:45 pm USED
		public static const MESSAGE_40:String = "This user has no presentations. Please contact server administrator.";  // updated 6/18 4:45 pm USED
		public static const UPDATE_MESSAGE:String = "Updates have been made to one or more of the core presentations. Any applicable updates may affect your customized presentations.";  // USED
		
		// V6
		public static const UPDATES_AVAILABLE_MESSAGE:String = "You have presentation updates available. Would you \n like to update now or skip this update? ";  // USED
		public static const GET_UPDATES_WANT_EM_OR_NOT:String = "Since updating was bypassed at your last login, \n automatic updates are occuring this session.";  // USED
		
		
		private static var _instance:DatabaseModel;
		
		//Detecting the optional unwanted decks
		public var  _optionalActive:Boolean =false;
		public var _unwantedVisibleGroup:Object;
		
		public var _showBranding:Boolean = true;
		public var _moreThanOneBrand:Boolean ; //NOTE
		public var _activateKeys:Boolean = false;
		
		public var dontShowBundleAlertAgain:Boolean = false;
		
		//==============================================================================================================
		// CONSTRUCT AND INIT
		//==============================================================================================================
		public function DatabaseModel(sing:String)
		{
			if ( sing != "sing" ) throw new Error("error");
			systemSQLConnection = new SQLConnection();
			customSQLConnection = new SQLConnection();
			//resolveDatabasePaths();
			dateFormatter = new DateFormatter();
			dateFormatter.formatString = 'MM/DD/YY';
		}
		public static function getInstance():DatabaseModel{
			if ( _instance == null)
			{
				_instance = new DatabaseModel("sing");
			}
			return _instance
		}
		public function resolveDatabasePaths():void
		{
			dbFolder = File.applicationStorageDirectory.resolvePath( "database/" );
			if( dbFolder.exists ){
				databaseAlreadyExists = true;
				mustDropOldTables = true;
				trace("database already exists");
				openDatabaseConnections();
			}
			else 
			{
				mustDropOldTables = false;
				dbFolder.createDirectory();
				if ( LoginPanel.MAC_BUILD)
				{
					systemSQLConnection.close();  // FOR MAC
					customSQLConnection.close();  // FOR MAC
					setTimeout(function(o:Object=null):void{
						openDatabaseConnections();
						trace("new database created");
					},2000);
				}
				else
				{
					openDatabaseConnections();
					trace("new database created");
				}
			}
		}
		public function openDatabaseConnections():void
		{
			systemDBFile = dbFolder.resolvePath( "SlideSystemDB.db" );
			customDBFile = dbFolder.resolvePath( "CustomDB.db" );
			try { 
				if ( ! systemSQLConnection.connected)
				{
					systemSQLConnection.open( systemDBFile ); //not asych
				}
				trace("Preset SQLConnection OPEN");
			}
			catch( error:SQLError ) { 
				trace("SQLConnection ERROR " + error.message);
				trace("Error Details: " + error.details);
				Alert.show("error opening database connections : " + error.details);
			}
			try { 
				if ( ! customSQLConnection.connected)
				{
					customSQLConnection.open( customDBFile ); //not asych	
				}				
				trace("Custom SQLConnection OPEN");
			}
			catch( error:SQLError ) { 
				trace("SQLConnection ERROR " + error.message);
				trace("Error Details: " + error.details);
				Alert.show("error opening database connections : " + error.details);
			}
		}
		public function closeDatabaseConnections():void
		{
			if( systemSQLConnection.connected ) systemSQLConnection.close();
			if( customSQLConnection.connected ) customSQLConnection.close();
		}
		//==============================================================================================================
		//==============================================================================================================
		// DELETE
		//==============================================================================================================
		//==============================================================================================================
		public function deleteAllWhere(sqlConnection:SQLConnection, tableName:String, columnName:String, value:* ):void
		{
			var dropStatement:SQLStatement = new SQLStatement();
			dropStatement.sqlConnection = sqlConnection;
			
			dropStatement.text = "DELETE FROM " + tableName + " WHERE " + columnName + " = " + value;
			
			try { 
				dropStatement.execute();
			}
			catch(error:SQLError) { 
				trace(" Error: " + dropStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				//throw new Error("error"); well hey we dont care if we can't drop tables that dont even exist anymore :)
			}
		}
		public function deleteCustomPresentation(guid:String, isDeleted:Boolean):void{
			
			// V6 make it a soft delete
			var dropStatement:SQLStatement = new SQLStatement();
			dropStatement.sqlConnection = customSQLConnection;
			
			dropStatement.text = "UPDATE presentations SET is_deleted = " + convertToBoolean(isDeleted) + " WHERE guid  = '" + guid + "'";
			
			try { 
				dropStatement.execute();
			}
			catch(error:SQLError) { 
				trace(" Error: " + dropStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				Alert.show("error deleting custom presentation"); 
				throw Error("fail");
			}
			
			
			return;
//			var dropStatement:SQLStatement = new SQLStatement();
//			dropStatement.sqlConnection = customSQLConnection;
//			
//			dropStatement.text = "DELETE FROM  presentations WHERE custom_presentation_id  = " + customPresentationId;
//			
//			try { 
//				dropStatement.execute();
//			}
//			catch(error:SQLError) { 
//				trace(" Error: " + dropStatement.text );
//				trace(" Message: " + error.message + " && Details: " + error.details);
//				Alert.show("error deleting custom presentation"); 
//			}			
		}
		
		public function deleteCustomPresentationsTitleSlide(customPresentationId:int):void{
			
			// V6 make it a soft delete
			var dropStatement:SQLStatement = new SQLStatement();
			dropStatement.sqlConnection = customSQLConnection;
			
			dropStatement.text = "DELETE FROM title_slide WHERE custom_presentation_id  = " + customPresentationId;
			
			try { 
				dropStatement.execute();
			}
			catch(error:SQLError) { 
				trace(" Error: " + dropStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				Alert.show("error deleting custom presentation"); 
				throw Error("fail");
			}
						
		}
		public function updateCustomPresentationIsPushed(guid:String, isPushed:Boolean):void{
			
			// V6 make it a soft delete
			var dropStatement:SQLStatement = new SQLStatement();
			dropStatement.sqlConnection = customSQLConnection;
			
			dropStatement.text = "UPDATE presentations SET is_pushed = " + convertToBoolean(isPushed) + " WHERE guid  = '" + guid + "'";
			
			try { 
				dropStatement.execute();
			}
			catch(error:SQLError) { 
				trace(" Error: " + dropStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				throw Error("fail");
			}
		}
		public function updateCustomPresentationUserLastSaved(guid:String, userLastSaved:String):void{
			
			// V6 make it a soft delete
			var dropStatement:SQLStatement = new SQLStatement();
			dropStatement.sqlConnection = customSQLConnection;
			
			dropStatement.text = "UPDATE presentations SET user_last_saved = " + userLastSaved + " WHERE guid  = '" + guid + "'";
			
			try { 
				dropStatement.execute();
			}
			catch(error:SQLError) { 
				trace(" Error: " + dropStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				throw Error("fail");
			}
		}
		public function deleteCustomPresentationSlides(customPresentationId:int):void{
			//V6 - make it a soft delete
//			return;
//			var dropStatement:SQLStatement = new SQLStatement();
//			dropStatement.sqlConnection = customSQLConnection;
//			
//			dropStatement.text = "DELETE FROM  slides WHERE presentation_id  = " + customPresentationId;
//			
//			try { 
//				dropStatement.execute();
//			}
//			catch(error:SQLError) { 
//				trace(" Error: " + dropStatement.text );
//				trace(" Message: " + error.message + " && Details: " + error.details);
//				Alert.show("error deleting custom presentation"); 
//			}			
		}
		public function deleteAllPresentationsAndOptionalDecksByIds(presentationsOrOptionalDecks:Array):void{
			var dropStatement:SQLStatement;
			for ( var i:uint =0; i <  presentationsOrOptionalDecks.length; i++)
			{
				var presentationOrOptionalDeckId:Number = Number(presentationsOrOptionalDecks[i]);
				
				// PRESENTATIONS
				
				// CUSTOM
				dropStatement = new SQLStatement();
				dropStatement.text = "DELETE FROM  presentations WHERE presentation_id  = " + presentationOrOptionalDeckId;
				dropStatement.sqlConnection = customSQLConnection;
				try { 
					dropStatement.execute();
				}
				catch(error:SQLError) { 
					trace(" Error: " + dropStatement.text );
					trace(" Message: " + error.message + " && Details: " + error.details);
					// Fail silently - there may not be such a presentation id
				}
				
				// SYSTEM
				dropStatement = new SQLStatement();
				dropStatement.text = "DELETE FROM  presentations WHERE presentation_id  = " + presentationOrOptionalDeckId;
				dropStatement.sqlConnection = systemSQLConnection;
				try { 
					dropStatement.execute();
				}
				catch(error:SQLError) { 
					trace(" Error: " + dropStatement.text );
					trace(" Message: " + error.message + " && Details: " + error.details);
					// Fail silently - there may not be such a presentation id
				}
				
				
				/* V6 - we have introduced a new table which must also be cleansed with this here action we are doing ! */
				// EITHER _ OR _ COMBINATIONS 
				// either_or_combinations
				
				
				// SYSTEM
				dropStatement = new SQLStatement();
				dropStatement.text = "DELETE FROM  either_or_combinations WHERE presentation_id  = " + presentationOrOptionalDeckId;
				dropStatement.sqlConnection = systemSQLConnection;
				try { 
				dropStatement.execute();
				}
				catch(error:SQLError) { 
				trace(" Error: " + dropStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				// Fail silently - there may not be such a presentation id
				}
				
				
				
				
				
				// OPTIONAL DECKS
				
				// SYSTEM
				dropStatement = new SQLStatement();
				dropStatement.text = "DELETE FROM  optional_decks WHERE optional_deck_id  = " + presentationOrOptionalDeckId;
				dropStatement.sqlConnection = systemSQLConnection;
				try { 
					dropStatement.execute();
				}
				catch(error:SQLError) { 
					trace(" Error: " + dropStatement.text );
					trace(" Message: " + error.message + " && Details: " + error.details);
					// Fail silently - there may not be such a presentation id
				}
				
				// CUSTOM
				dropStatement = new SQLStatement();
				dropStatement.text = "DELETE FROM  optional_decks WHERE optional_deck_id  = " + presentationOrOptionalDeckId;
				dropStatement.sqlConnection = customSQLConnection;
				try { 
					dropStatement.execute();
				}
				catch(error:SQLError) { 
					trace(" Error: " + dropStatement.text );
					trace(" Message: " + error.message + " && Details: " + error.details);
					// Fail silently - there may not be such a presentation id
				}
				
				//=====================================
				// NOW DELETE THE SLIDES TOO
				//=====================================
				// CUSTOM
				// below won't do at all
				// this presentationOrOptionalDeckId is the system presentation id but on a customSQLConnection we need the custom_presentation_id 
				var customPresentationsBasedOnCorePresentationIds:Array = getWhere(customSQLConnection,"presentations","presentation_id",presentationOrOptionalDeckId);
				if ( customPresentationsBasedOnCorePresentationIds != null && customPresentationsBasedOnCorePresentationIds.length > 0 )
				{
					for ( var qq:uint = 0 ; qq < customPresentationsBasedOnCorePresentationIds.length; qq++)
					{
						var customPresentation:Object = customPresentationsBasedOnCorePresentationIds[qq];
						var customPresId:uint = customPresentation.custom_presentation_id;
						
						dropStatement = new SQLStatement();
						dropStatement.text = "DELETE FROM  slides WHERE presentation_id  = " + customPresId;
						dropStatement.sqlConnection = customSQLConnection;
						try { 
							dropStatement.execute();
						}
						catch(error:SQLError) { 
							trace(" Error: " + dropStatement.text );
							trace(" Message: " + error.message + " && Details: " + error.details);
							// Fail silently - there may not be such a presentation id  
						}
					}
				}
				
				// SYSTEM
				dropStatement = new SQLStatement();
				dropStatement.text = "DELETE FROM  slides WHERE presentation_id  = " + presentationOrOptionalDeckId;
				dropStatement.sqlConnection = systemSQLConnection;
				try { 
					dropStatement.execute();
				}
				catch(error:SQLError) { 
					trace(" Error: " + dropStatement.text );
					trace(" Message: " + error.message + " && Details: " + error.details);
					// Fail silently - there may not be such a presentation id
				}
			}
		}
		public function deleteSlidesAloneByIds(slidesAlone:Array):void{
			var dropStatement:SQLStatement;
			for ( var i:uint =0; i <  slidesAlone.length; i++)
			{
				var slideAloneId:Number = Number(slidesAlone[i]);
				// CUSTOM
				dropStatement = new SQLStatement();
				dropStatement.text = "DELETE FROM  slides_alone WHERE slide_id  = " + slideAloneId;
				dropStatement.sqlConnection = customSQLConnection;
				try { 
					dropStatement.execute();
				}
				catch(error:SQLError) { 
					trace(" Error: " + dropStatement.text );
					trace(" Message: " + error.message + " && Details: " + error.details);
					// Fail silently - there may not be such a presentation id
				}
				// SYSTEM
				dropStatement = new SQLStatement();
				dropStatement.text = "DELETE FROM  slides_alone WHERE slide_id  = " + slideAloneId;
				dropStatement.sqlConnection = systemSQLConnection;
				try { 
					dropStatement.execute();
				}
				catch(error:SQLError) { 
					trace(" Error: " + dropStatement.text );
					trace(" Message: " + error.message + " && Details: " + error.details);
					// Fail silently - there may not be such a presentation id
				}
			}
		}
		public function deleteBundlesByIds(bundles:Array):void{
			var dropStatement:SQLStatement;
			for ( var i:uint =0; i <  bundles.length; i++)
			{
				var bundleId:Number = Number(bundles[i]);
				
				// CUSTOM
				dropStatement = new SQLStatement();
				dropStatement.text = "DELETE FROM  bundles WHERE bundle_id  = " + bundleId;
				dropStatement.sqlConnection = customSQLConnection;
				try { 
					dropStatement.execute();
				}
				catch(error:SQLError) { 
					trace(" Error: " + dropStatement.text );
					trace(" Message: " + error.message + " && Details: " + error.details);
					// Fail silently - there may not be such a presentation id
				}
				// SYSTEM
				dropStatement = new SQLStatement();
				dropStatement.text = "DELETE FROM  bundles WHERE bundle_id  = " + bundleId;
				dropStatement.sqlConnection = systemSQLConnection;
				try { 
					dropStatement.execute();
				}
				catch(error:SQLError) { 
					trace(" Error: " + dropStatement.text );
					trace(" Message: " + error.message + " && Details: " + error.details);
					// Fail silently - there may not be such a presentation id
				}
			}
		}
		//====================================================================================================================
		//====================================================================================================================
		//  GET
		//====================================================================================================================
		//====================================================================================================================
		
		public function getWhere(sqlConnection:SQLConnection, tableName:String, columnName:String, value:*):Array
		{
			var result:SQLResult;
			var resultArray:Array = new Array();
			var selectStatement:SQLStatement = new SQLStatement();
			selectStatement.sqlConnection = sqlConnection;
			
			selectStatement.text = "SELECT * FROM " + tableName + " WHERE " + columnName + " = " + value;
			
			try { 
				selectStatement.execute();
				
				result = selectStatement.getResult();
				
				if( result.data ) { 
					for( var i:uint = 0; i < result.data.length; i++ ) { 
						resultArray[resultArray.length] = result.data[i];
					}
				}
				else { 
					//return null;
					//we want to return an empty array
				}
			}
			catch( error:SQLError ) { 
				trace(" Error: " + selectStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				Alert.show("ERROR : text : " + selectStatement.text + " : details : " + error.details,"ERROR");
				throw new Error("error");
			}
			return resultArray;
		}
		//============================================================================
		// USERS TABLE STUFF
		//============================================================================
		
		public function getLastUserFromUsersTable():Array{
			var result:SQLResult;
			var resultVec:Array = new Array();
			var selectStatement:SQLStatement = new SQLStatement();
			selectStatement.sqlConnection = systemSQLConnection;
			
			selectStatement.text = "SELECT * FROM users"; 
			
			try { 
				selectStatement.execute();
				
				result = selectStatement.getResult();
				
				if( result.data ) { 
					for( var i:uint = 0; i < result.data.length; i++ ) { 
						resultVec[resultVec.length] = result.data[i];
					}
				}
				else { 
					return null; 
				}
			}
			catch( error:SQLError ) { 
				trace(" Error: " + selectStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				//Alert.show("ERROR : text : " + selectStatement.text + " : details : " + error.details,"ERROR"); no problem just return null				
			}
			return resultVec;
		}
		
		public function getUserWithUserHash(userHash:String):Object
		{
			var result:SQLResult;
			var resultObject:Object = new Object();
			var selectStatement:SQLStatement = new SQLStatement();
			selectStatement.sqlConnection = systemSQLConnection;
			
			selectStatement.text = "SELECT * FROM users WHERE user_hash = '" + userHash + "'";
			
			try { 
				selectStatement.execute();
				
				result = selectStatement.getResult();
				
				if( result && result.data ) {
					
					resultObject = result.data[0];
					if ( result.data.length > 1 )
					{
						Alert.show("More than one user in the user table");
					}					
				}
				else { 
					return null;
				}
			}
			catch( error:SQLError ) { 
				trace(" Error: " + selectStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				return null;
			}
			return resultObject;
		}
		public function getUserWithUserName(userName:String):Object
		{
			var result:SQLResult;
			var resultObject:Object = new Object();
			var selectStatement:SQLStatement = new SQLStatement();
			selectStatement.sqlConnection = systemSQLConnection;
			
			selectStatement.text = "SELECT * FROM users WHERE user_name = '" + userName + "'";
			
			try { 
				selectStatement.execute();
				
				result = selectStatement.getResult();
				
				if( result && result.data ) {
					
					resultObject = result.data[0];
					//					if ( result.data.length > 1 )
					//					{
					//						Alert.show("More than one user in the user table");
					//					}					
				}
				else { 
					return null;
				}
			}
			catch( error:SQLError ) { 
				trace(" Error: " + selectStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				return null;
			}
			return resultObject;
		}
		public function updateUsersTableWithWorkedOfflineIsTrue(username:String):void{
			
			var slideInsertStatement:SQLStatement = new SQLStatement();
			slideInsertStatement.sqlConnection = systemSQLConnection;
			
			slideInsertStatement.text = "UPDATE users";
			trace("wagwan");
			slideInsertStatement.text += " SET " + 
				" has_worked_offline = " + convertToBoolean(true); 
								
			
			try { 
				slideInsertStatement.execute();
				trace(" user has worked offline updated to true --DatabseModel.as ");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + slideInsertStatement.text);
				trace(" Details: " + error.details);
				throw new Error("error");
			}
		}
		public function insertUserIntoUsersTableWhenAllDownloadsAreComplete(username:String, userHash:String, lastUpdated:String, brandsArray:Array):void{
			
			trace("TRACE UNIX TIME  insertUserIntoUsersTableWhenAllDownloadsAreComplete"+lastUpdated);
			// we are only required to maintain one user on any system so first we drop the last user and then insert the new one
			var dropStatement:SQLStatement = new SQLStatement();
			dropStatement.sqlConnection = this.systemSQLConnection;
			
			//dropStatement.text = "DELETE FROM users";
			dropStatement.text = "DROP TABLE IF EXISTS 'users'";
			
			try { 
				dropStatement.execute();
			}
			catch(error:SQLError) { 
				trace(" Error: " + dropStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);	  			
			}
			
			
			
			
			var createTableStatement:SQLStatement = new SQLStatement();
			createTableStatement.sqlConnection = systemSQLConnection;
			
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
				trace(" users Table CREATED successfully!!!!!!!!!!!!");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + createTableStatement.text);
				trace(" Details: " + error.details);
				Alert.show("Error : " + error.details);
			}
			
			
			
			
			var insertStatement:SQLStatement = new SQLStatement();
			insertStatement.sqlConnection = this.systemSQLConnection; 
			
			var hasNnpe:Boolean = false;
			var hasExcel:Boolean = false;
			var brandObject : Object;
			for ( var i :uint = 0; i < brandsArray.length; i++)
			{
				brandObject = brandsArray[i] as Object;
				if ( brandObject.hasOwnProperty("id") && brandObject.hasOwnProperty("name")) 
				{
					if ( (brandObject.name as String).toLowerCase() == "excel")
					{
						hasExcel = true;
					}
					if ( (brandObject.name as String).toLowerCase() == "nnpe")
					{
						hasNnpe = true;
					}
				}
			}				
			
			insertStatement.text = "INSERT OR REPLACE INTO users";
			
			insertStatement.text += " SELECT '" + 
				username + "' AS user_name, '" +		
				userHash + "' AS user_hash, '" +
				lastUpdated + "' AS last_updated, " +
				
				convertToBoolean(hasExcel) + " AS hasExcel, " +
				convertToBoolean(hasNnpe) + " AS hasNnpe, " +
				
				1 + " AS all_files_have_been_downloaded, " +
				
				convertToBoolean(false) + " AS has_worked_offline ";
			
			try { 
				insertStatement.execute();
				var date:Date = new Date();
				date.time = Number(lastUpdated) * 1000;
				trace(" user inserted with all downloads complete at "+lastUpdated+" or " + date);
			}
			catch( error:SQLError ) { 
				trace(" Error: " + insertStatement.text);
				trace(" Details: " + error.details);
				Alert.show("ERROR : text : " + insertStatement.text + " : details : " + error.details,"ERROR");
				throw new Error("error");
			}
		}
		//=========================================================================================
		
		public function getAllSlides(sqlConnection:SQLConnection):Array{
			var result:SQLResult;
			var resultVec:Array = new Array();
			var selectStatement:SQLStatement = new SQLStatement();
			selectStatement.sqlConnection = sqlConnection;
			
			selectStatement.text = "SELECT * FROM slides_alone"; 
			
			try { 
				selectStatement.execute();
				
				result = selectStatement.getResult();
				
				if( result.data ) { 
					for( var i:uint = 0; i < result.data.length; i++ ) { 
						resultVec[resultVec.length] = result.data[i];
					}
				}
				else { 
					//return null; we want to return an empty array
				}
			}
			catch( error:SQLError ) { 
				trace(" Error: " + selectStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				Alert.show("ERROR : text : " + selectStatement.text + " : details : " + error.details,"ERROR");
				throw new Error("error");
			}
			return resultVec;
		}
		public function getPresentation(sqlConnection:SQLConnection, presentationId:uint):Object
		{
			var result:SQLResult;
			var selectStatement:SQLStatement = new SQLStatement();
			selectStatement.sqlConnection = sqlConnection;
			
			selectStatement.text = "SELECT * FROM presentations WHERE presentation_id=" + presentationId + " LIMIT 1";
			
			try { 
				selectStatement.execute();
				
				result = selectStatement.getResult();
				if( result.data ) { 
					return result.data[0]; //first index
				}
				else { 
					return false;
				}
			}
			catch( error:SQLError ) { 
				trace(" Error: " + selectStatement.text);
				trace(" Message: " + error.message + " && Details: " + error.details);
				Alert.show("ERROR : text : " + selectStatement.text + " : details : " + error.details,"ERROR");
				throw new Error("error");
			}
			return false;
		}
		public function getAllPresentationsByDate(sqlConnection:SQLConnection):Array
		{
			var result:SQLResult;
			var resultArray:Array = new Array();
			var selectStatement:SQLStatement = new SQLStatement();
			selectStatement.sqlConnection = sqlConnection;
			
			selectStatement.text = "SELECT * FROM presentations ORDER BY DATE(date_created) ASC";
			
			try { 
				selectStatement.execute();
				
				result = selectStatement.getResult();
				
				if( result.data ) { 
					for( var i:uint = 0; i < result.data.length; i++ ) { 
						resultArray[resultArray.length] = result.data[i];
					}
				}
			}
			catch( error:SQLError ) { 
				trace(" Error: " + selectStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				Alert.show("ERROR : text : " + selectStatement.text + " : details : " + error.details,"ERROR");
				throw new Error("error");
			}
			return resultArray;
		}
		public function getAllOptionalDecks(sqlConnection:SQLConnection):Array
		{
			var result:SQLResult;
			var resultArray:Array = new Array();
			var selectStatement:SQLStatement = new SQLStatement();
			selectStatement.sqlConnection = sqlConnection;
			
			selectStatement.text = "SELECT * FROM optional_decks";
			
			try { 
				selectStatement.execute();
				
				result = selectStatement.getResult();
				
				if( result.data ) { 
					for( var i:uint = 0; i < result.data.length; i++ ) { 
						resultArray[resultArray.length] = result.data[i];
					}
				}
			}
			catch( error:SQLError ) { 
				trace(" Error: " + selectStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				Alert.show("ERROR : text : " + selectStatement.text + " : details : " + error.details,"ERROR");
				throw new Error("error");
			}
			return resultArray;
		}
		public function getAll(sqlConnection:SQLConnection, tableName:String, orderByColumn:String = "", order:String = "" ):Array
		{
			var result:SQLResult;
			var resultArray:Array = new Array();
			var selectStatement:SQLStatement = new SQLStatement();
			selectStatement.sqlConnection = sqlConnection;
			
			selectStatement.text = "SELECT * FROM " + tableName + ((orderByColumn.length > 0) ? " ORDER BY " + orderByColumn + " " + order : "");
			
			try { 
				selectStatement.execute();
				
				result = selectStatement.getResult();
				
				if( result.data ) { 
					for( var i:uint = 0; i < result.data.length; i++ ) { 
						resultArray[resultArray.length] = result.data[i];
					}
				}
			}
			catch( error:SQLError ) { 
				trace(" Error: " + selectStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				Alert.show("ERROR : text : " + selectStatement.text + " : details : " + error.details,"ERROR");
				throw new Error("error");
			}
			return resultArray;
		}
		
		//===================================================================================================
		//===================================================================================================
		//===================================================================================================
		//										 INSERT
		//===================================================================================================
		//===================================================================================================
		//===================================================================================================
		
		
		//===================================================================================================
		//			SLIDES ALONE
		//===================================================================================================
		public function insertSlidesAloneData( slidesAloneData:Object, sqlConnection:SQLConnection , chunkNumber:uint = 0):void
		{
			
			/* 
			With V3 we are introducing a new column into the slides alone data table
			since this version must be backwards compatible with previous versions we must
			migrate old data into the new table or simulate as much :
			
			we can simulate it by dropping the old table and making a new user JSON call ( wether its a new user
			or not ) , gathering all new data, dropping the old table and inserting the new one in one shot.
			
			in the special case of an offline user logging in we have to use the old system for now
			but at least in this case we will never be inserting new slides data into database.			
			
			*/
			
			// NOTE : if there are more than 500 slides they cannot be inserted in one shot or the 'too many terms in compound SELECT' SQLite error will be thrown ergo we chunkify
			
			var makeChunks:Boolean = false;
			
			var i:uint;
			trace("inserting slides data...");
			if( slidesAloneData.length > 0 ) { 
				var slide:Object;
				var filename:String;
				var filetype:int;
				
				var slideFilesInsertStatement:SQLStatement
				var slideInsertStatement:SQLStatement = new SQLStatement();
				slideInsertStatement.sqlConnection = sqlConnection; //dbModel.systemSQLConnection;
				
				slideInsertStatement.text = "INSERT OR REPLACE INTO slides_alone";
				slide = slidesAloneData[chunkNumber];
				populateSwfFieldOfSlide(slide);
				var slideNotes:String = slide.notes as String;
				if ( slideNotes )
				{
					slideNotes = slideNotes.split("'").join("''");
				}else{
					slideNotes = "Review as stated.";
				}
				slideInsertStatement.text += " SELECT '" + slide.id + "' AS slide_id, '" + 
					slideNotes + "' AS notes, '" + 
					slide.thumbnail + "' AS thumbnail, '" +
					slide.printable_pdf + "' AS printable_pdf, '" +
					slide.swf + "' AS swf, '" +
					slide.flv + "' AS flv, " +
					convertToBoolean(slide.is_animated) + " AS is_animated ";
				
				
				for( i = chunkNumber + 1; i < slidesAloneData.length; i++ ) { 
					
					slide = slidesAloneData[i];
					populateSwfFieldOfSlide(slide);
					slideNotes = slide.notes as String;
					if ( slideNotes )
					{
						slideNotes = slideNotes.split("'").join("''");
					}else{
						slideNotes = "Review as stated.";
					}
					slideInsertStatement.text += "UNION SELECT '" +
						slide.id + "', '" + 
						slideNotes + "', '" + 
						slide.thumbnail + "', '" +
						slide.printable_pdf + "', '" +
						slide.swf + "', '" +
						slide.flv + "', " +
						convertToBoolean(slide.is_animated) + " ";
					
						if ( i > 498 + chunkNumber )
						{
							makeChunks = true;
							break;
						}
				}
				
				try { 
					slideInsertStatement.execute();
					trace(" Slide " + slidesInserted + " inserted successfully! ");
					slidesInserted++;
				}
				catch( error:SQLError ) { 
					trace(" Error: " + error.message);
					trace(" Details: " + error.details);
					Alert.show("Error : " + error.details);
				}
			}
			else { 
				trace("!!!!! THERE ARE NO SLIDES DATA !!!!!");
			}
			if ( makeChunks )
			{
				insertSlidesAloneData( slidesAloneData, sqlConnection , 500 + chunkNumber);
			}
		}
		private function populateSwfFieldOfSlide(slide:Object):void{
			for ( var i:uint = 0 ; i < slide.files.length; i++)
			{
				var slideFile:String = slide.files[i].file_name as String;
				var nameArray:Array = slideFile.split(".");
				var mimeType:String = nameArray[nameArray.length-1];
				if ( mimeType == "swf" )
				{
					slide.swf = slideFile;
				}		
				if ( mimeType == "flv" )
				{
					slide.flv = slideFile;
				}		
			}
		}
		//===================================================================================================
		//			BUNDLES ALONE
		//===================================================================================================
		public function insertBundlesAloneData(bundlesAloneData:Object, sqlConnection:SQLConnection ):void{
			trace("inserting bundles...");
			if( bundlesAloneData.length > 0 ) { 
				var bundle:Object;
				
				var bundleInsertStatement:SQLStatement = new SQLStatement();
				bundleInsertStatement.sqlConnection = sqlConnection; //dbModel.systemSQLConnection;
				
				/*" bundle_id INTEGER PRIMARY KEY NOT NULL, " + 
				" size INTEGER, " + 
				" keep_whole BOOLEAN, " + 
				" is_sequential BOOLEAN, " + 
				" is_adjacent BOOLEAN, " + 
				" mandatory BOOLEAN " + 
				" )";*/
				
				bundle = bundlesAloneData[0];
				bundleInsertStatement.text = "INSERT OR REPLACE INTO bundles";
				bundleInsertStatement.text += " SELECT '" + bundle.id + "' AS bundle_id, '" + bundle.size + "' AS size, " + ((convertToBoolean(bundle.keep_whole) == 1) ? 1 : 0 ) + " AS keep_whole, " + convertToBoolean(bundle.in_sequence) + " AS is_sequential, " + convertToBoolean(bundle.adjacent) + " AS is_adjacent, " + convertToBoolean(bundle.mandatory) + " AS mandatory ";
				
				var i : uint;
				for( i = 1; i < bundlesAloneData.length; i++ ) { 
					
					bundle = bundlesAloneData[i];
					
					//bundleInsertStatement.text = "INSERT OR REPLACE INTO bundles";
					//bundleInsertStatement.text += " SELECT '" + bundle.id + "' AS bundle_id, '" + bundle.size + "' AS size, " + ((convertToBoolean(bundle.keep_whole) == 0) ? 1 : 0 ) + " AS is_flexible, " + convertToBoolean(bundle.in_sequence) + " AS is_sequential, " + convertToBoolean(bundle.adjacent) + " AS is_adjacent";
					
					bundleInsertStatement.text += " UNION SELECT '" + bundle.id + "', '" + bundle.size + "', " + ((convertToBoolean(bundle.keep_whole) == 1) ? 1 : 0 ) + ", " + convertToBoolean(bundle.in_sequence) + ", " + convertToBoolean(bundle.adjacent) + ", " + convertToBoolean(bundle.mandatory);
				}
				
				try { 
					bundleInsertStatement.execute();
					//trace(" Bundles inserted successfully! ");
				}
				catch( error:SQLError ) { 
					trace(" Error: " + bundleInsertStatement.text);
					trace(" Details: " + error.details);
					Alert.show("Error : " + error.details);
				}
			}
			else { 
				trace("!!!!! THERE ARE NO BUNDLES DATA !!!!!");
			}
		}
		
		//=====================================================================================================
		// MAIN INSERTION HERE -- PRESENTATIONS
		//=====================================================================================================
		
		public function addResourcesTitleAndResourcesOrderColumnsToPresentationsTableIfTheyDontAlreadyExist( sqlConnection:SQLConnection ):void{
			
			sqlConnection.loadSchema( SQLTableSchema , "presentations" );
			var schemaResult:SQLSchemaResult = sqlConnection.getSchemaResult();
			
			var tableSchema:SQLTableSchema = schemaResult.tables[0];
			var columnsArray:Array = tableSchema.columns;
			
			var haveTitle:Boolean = false;
			var haveOrder:Boolean = false;
			
			for ( var i:uint = 0 ; i < columnsArray.length; i++ )
			{
				var column:SQLColumnSchema = columnsArray[i];
				if ( column.name == "resources_title" )
				{
					// we already have this column
					haveTitle = true;
				}
				if ( column.name == "resources_order" )
				{
					// we already have this column
					haveOrder = true;
				}
			}
			
			//ALTER TABLE tbl_status ADD COLUMN status_default TEXT
			if ( ! haveTitle )
			{
				var addColumnStatement:SQLStatement = new SQLStatement();
				addColumnStatement.sqlConnection = sqlConnection;
			
				addColumnStatement.text = "ALTER TABLE presentations ADD COLUMN resources_title TEXT";
			
				try { 
					addColumnStatement.execute();
				}
				catch( error:SQLError ) { 
					trace(" Error: " + addColumnStatement.text);
					trace(" Details: " + error.details);
					Alert.show("Error : " + error.details);
				}
			}
			if ( ! haveOrder )
			{
				var addColumnStatement2:SQLStatement = new SQLStatement();
				addColumnStatement2.sqlConnection = sqlConnection;
				
				addColumnStatement2.text = "ALTER TABLE presentations ADD COLUMN resources_order TEXT";
				
				try { 
					addColumnStatement2.execute();
				}
				catch( error:SQLError ) { 
					trace(" Error: " + addColumnStatement2.text);
					trace(" Details: " + error.details);
					Alert.show("Error : " + error.details);
				}
			}
		}

		public function insertPresentationsData( presentationsData:Object, sqlConnection:SQLConnection ):void
		{
			
			// NOTE : For V5.0 it was decided to add another column to the presenations table in order to store the 
			// value of each deck's resources title. Since we want backwards compatability we don't drop and create 
			// a new table we simply add the column on the fly ( if it does not already exist )
			
			addResourcesTitleAndResourcesOrderColumnsToPresentationsTableIfTheyDontAlreadyExist( sqlConnection );	
			
			var i:uint = 0;
			var j:uint = 0;
			var k:uint = 0;
			
			trace("inserting presentations data...");
			
			if( presentationsData.Presentations.length > 0 ) { 
				var presentation:Object;
				var presentationInsertStatement:SQLStatement = new SQLStatement();
				presentationInsertStatement.sqlConnection = sqlConnection; //dbModel.systemSQLConnection;
				
				presentationInsertStatement.text = "INSERT OR REPLACE INTO presentations";
				
				for( i = 0; i < presentationsData.Presentations.length; i++ ) { 
					
					// presentation is the JSON object !
					presentation = presentationsData.Presentations[i];
					trace(" about to insert Presentation : " + presentation.id );
					
					var explode:Array = String(presentation.date_created).split("/");
					var modifiedDate:String = "20" + explode[2] + "-" + ((String(explode[0]).length > 1) ? explode[0] : "0" + explode[0]) + "-" + ((String(explode[1]).length > 1) ? explode[1] : "0" + explode[1] );
					
					var safeTitle:String = ( presentation.hasOwnProperty("resources_title") && presentation.resources_title != null ? presentation.resources_title : "" );
					var safeOrder:Number = ( presentation.hasOwnProperty("resources_order") && presentation.resources_order > 0 ? presentation.resources_order : 0 );
					
					if( i == 0 ) { 
						
						presentationInsertStatement.text += " SELECT '" + 
							presentation.id + "' AS presentation_id, '" + 
							escapeSingleQuotes(presentation.deck_name) + "' AS presentation_name, '" + 
							modifiedDate  + "' AS date_created, '" + 
							presentation.brand_id + "' AS brand_id, " + 
							convertToBoolean(presentation.locked) + " AS is_locked, " + 
							"''" + " AS custom_title, '" + 
							presentation.printable_pdf + "' AS printable_pdf, " +
							presentation.sequence_locked + " sequence_locked, " +
							presentation.sections[0].id + " AS sectionId, '" +
							escapeSingleQuotes(safeTitle) + "' AS resources_title, " +
							safeOrder + " AS resources_order "; 
					}
					else { 
						presentationInsertStatement.text += " UNION SELECT '" + 
							presentation.id + "', '" + 
							escapeSingleQuotes(presentation.deck_name) + "', '" + 
							modifiedDate + "', '" + 
							presentation.brand_id + "', " + 
							convertToBoolean(presentation.locked) + 
							", '', '" + 
							presentation.printable_pdf + "', " +
							presentation.sequence_locked + ", " + 
							presentation.sections[0].id + ", '" +
							escapeSingleQuotes(safeTitle) + "', " +
							safeOrder + " ";
					}
					
					if( presentation.sections && presentation.sections.length > 0 ) { 
						var section:Object;
						
						var sectionInsertStatement:SQLStatement = new SQLStatement();
						sectionInsertStatement.sqlConnection = sqlConnection; //dbModel.systemSQLConnection;
						
						sectionInsertStatement.text = "INSERT OR REPLACE INTO sections";
						
						for( j = 0; j < presentation.sections.length; j++ ) { 
							section = presentation.sections[j];
							
							if( j == 0 ) { 
								sectionInsertStatement.text += " SELECT '" + section.id + "' AS section_in_presentation_id, '" + 
									presentation.id + "' AS presentation_id, '" + 
									escapeSingleQuotes(section.section_name) + "' AS section_name, '" + 
									section.sequence + "' AS sequence," +
									"0" + " AS is_sequential";
							}
							else { 
								sectionInsertStatement.text += " UNION SELECT '" + section.id + "', '" + 
									presentation.id + "', '" + 
									escapeSingleQuotes(section.section_name) + "', '" + 
									section.sequence + 
									"', 0";
							}
							
							if( section.slides && section.slides.length > 0 ) { 
								var slide:Object;
								
								var slideInsertStatement:SQLStatement = new SQLStatement();
								slideInsertStatement.sqlConnection = sqlConnection; 
								
								slideInsertStatement.text = "INSERT OR REPLACE INTO slides";
								
								for( k = 0; k < section.slides.length; k++ ) { 
									slide = section.slides[k];
									
									if( k == 0 ) { 
										slideInsertStatement.text += " SELECT " + 
											slide.section_slide_id + " AS section_slide_id, " +
											slide.slide_id + " AS slide_id, " + 
											section.id + " AS section_id, " + 
											presentation.id + " AS presentation_id, " + 
											slide.bundle_id  + " AS bundle_id, " + 
											slide.bundle_position + " AS bundle_position, " + 
											slide.sequence + " AS sequence, " + 
											convertToBoolean(slide.locked_to_section) + " AS is_locked, " + 
											convertToBoolean(slide.mandatory) + " AS is_mandatory, " +											 
											"0 AS unwanted"; 
									}
									else { 
										slideInsertStatement.text += " UNION SELECT " + 
											slide.section_slide_id + ", " +
											slide.slide_id + ", " + 
											section.id + ", " + 
											presentation.id + ", " + 
											slide.bundle_id + ", " +
											slide.bundle_position + ", " +
											slide.sequence + ", " + 
											convertToBoolean(slide.locked_to_section) + ", " + 
											convertToBoolean(slide.mandatory) + ", " + 
											"0";
									}
								}	
								
								try { 
									slideInsertStatement.execute();
									//trace(" Slide : " + slide.slide_id + " inserted successfully! ");
								}
								catch( error:SQLError ) { 
									trace(" Error: " + slideInsertStatement.text);
									trace(" Details: " + error.details);
									// V6 TODO POST the error data to Kevin ! Alert.show("Error : " + error.details);
								}
							}
							else { 
								trace("!!!!! THERE ARE NO SLIDES IN SECTIONS IN THIS PRESENTATION !!!!!");
							}
						}
						
						try { 
							sectionInsertStatement.execute();
						}
						catch( error:SQLError ) { 
							trace(" Error: " + sectionInsertStatement.text);
							trace(" Details: " + error.details);
							// V6 TODO POST the error data to Kevin ! Alert.show("Error : " + error.details);
						}
					}
					else { 
						trace("!!!!! THERE ARE NO SECTIONS IN THIS PRESENTATION !!!!!");
					}
				}
				
				try { 
					presentationInsertStatement.execute();
					trace(" Presentation : " + presentation.id + " inserted successfully! ");
				}
				catch( error:SQLError ) { 
					trace(" Error: " + presentationInsertStatement.text);
					trace(" Details: " + error.details);
					// V6 TODO POST the error data to Kevin ! Alert.show("Error : " + error.details);
				}
				var obj:Object = getAll(systemSQLConnection,"slides");
				trace(obj)
			}
			else { 
				trace("!!!!! THERE IS NO PRESENTATIONS DATA !!!!!");
			}
		}
		
		public function insertASinglePresentationObjectIntoPresentationsTable( presentation:Object, sqlConnection:SQLConnection ):void
		{
			// THIS IS ONLY FOR CUSTOM PRESENTATIONS !
			addResourcesTitleAndResourcesOrderColumnsToPresentationsTableIfTheyDontAlreadyExist( sqlConnection );
			
			var i:uint = 0;
			var j:uint = 0;
			var k:uint = 0;
			
			var presentationInsertStatement:SQLStatement = new SQLStatement();
			presentationInsertStatement.sqlConnection = sqlConnection; //dbModel.systemSQLConnection;
			
			presentationInsertStatement.text = "INSERT OR REPLACE INTO presentations";
			
			//var explode:Array = String(presentation.date_created).split("/");
			//var modifiedDate:String = "20" + explode[2] + "-" + ((String(explode[0]).length > 1) ? explode[0] : "0" + explode[0]) + "-" + ((String(explode[1]).length > 1) ? explode[1] : "0" + explode[1] );
			
			var safeTitle:String = ( presentation.hasOwnProperty("resources_title") && presentation.resources_title != null ? presentation.resources_title : "" );
			var safeOrder:Number = ( presentation.hasOwnProperty("resources_order") && presentation.resources_order > 0 ? presentation.resources_order : 0 );
			
			presentationInsertStatement.text += " SELECT '" + 
				presentation.custom_presentation_id + "' AS custom_presentation_id, '" +
				presentation.presentation_id + "' AS presentation_id, '" + 
				escapeSingleQuotes(presentation.presentation_name) + "' AS presentation_name, '" + 
				presentation.date_created  + "' AS date_created, '" + 
				presentation.brand_id + "' AS brand_id, " + 
				convertToBoolean(presentation.is_locked) + " AS is_locked, '" + 
				escapeSingleQuotes(presentation.custom_title) + "' AS custom_title, '" + 
				presentation.printable_pdf + "' AS printable_pdf, " +
				presentation.sequence_locked + " AS sequence_locked, " +
				presentation.sectionId + " AS sectionId, '" +
				escapeSingleQuotes(safeTitle) + "' AS resources_title, " +
				safeOrder + " AS resources_order, " + //creating V5 data for testing migration to V6 
				// V6 ADDED BELOW
				convertToBoolean(presentation.is_pushed) + " AS is_pushed, " +
				"'" + presentation.guid + "' AS guid, " + 
				convertToBoolean(presentation.is_deleted) + " AS is_deleted, '" +
				presentation.user_last_saved + "' AS user_last_saved ";
				
			
			// presentations
			// is_pushed
			// guid
			// is_deleted
			// user_last_saved
			
			try { 
				presentationInsertStatement.execute();
				trace(" Presentations inserted successfully! --DatabseModel.as ");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + presentationInsertStatement.text);
				trace(" Details: " + error.details);
				throw new Error("error");
			}
		}
		
		
		public function insertAnArrayOfSlidesIntoCoreSlidesTable(slides:Array, sectionId:Object, presentationId:int):void{
			
			var k:uint = 0;
			var slide:Object;
			
			var slideInsertStatement:SQLStatement = new SQLStatement();
			slideInsertStatement.sqlConnection = systemSQLConnection; 
			
			slideInsertStatement.text = "INSERT OR REPLACE INTO slides";
			
			for( k = 0; k <slides.length; k++ ) { 
				slide = slides[k];
				
				slideInsertStatement.text = "INSERT OR REPLACE INTO slides";
				
				slideInsertStatement.text += " SELECT " + 
					slide.section_slide_id + " AS section_slide_id, " +
					slide.slide_id + " AS slide_id, " + 
					sectionId + " AS section_id, " + 
					presentationId + " AS presentation_id, " + 
					slide.bundle_id  + " AS bundle_id, " + 
					slide.bundle_position + " AS bundle_position, " + 
					slide.sequence + " AS sequence, " + 
					convertToBoolean(slide.locked_to_section) + " AS is_locked, " + 
					slide.mandatory + " AS is_mandatory, " +    //convertToBoolean(slide.mandatory) + " AS is_mandatory, " + 3/18											 
					convertToBoolean(slide.unwanted) + " AS unwanted";				//convertToBoolean(slide.unwanted) + " AS unwanted";
				
				
				try { 
					slideInsertStatement.execute();
				}
				catch( error:SQLError ) { 
					trace(" Error: " + slideInsertStatement.text); 
					trace(" Details: " + error.details);
					throw new Error("error");
				}
			}
		}
		
		
		public function insertASingleSlideIntoOptionalSlidesTable(slide:Object, sectionId:Object, optionalDeckId:int):void{
			
			var slideInsertStatement:SQLStatement = new SQLStatement();
			slideInsertStatement.sqlConnection = systemSQLConnection; 
			slideInsertStatement.text = "INSERT OR REPLACE INTO optional_slides";
			slideInsertStatement.text += " SELECT " + 
				slide.slide_id + " AS slide_id, " + 
				sectionId + " AS section_id, " + 
				optionalDeckId + " AS optional_deck_id, " + 
				slide.section_slide_id + " AS section_slide_id, " +
				slide.bundle_id  + " AS bundle_id, " + 
				slide.bundle_position + " AS bundle_position, " + 
				slide.sequence + " AS sequence, " + 
				"0 AS unwanted";				
			try { 
				slideInsertStatement.execute();
			}
			catch( error:SQLError ) { 
				trace(" Error: " + slideInsertStatement.text);
				trace(" Details: " + error.details);
				Alert.show("ERROR : text : " + slideInsertStatement.text + " : details : " + error.details,"ERROR");
				throw new Error("error");
			}// done inserting slides
			
		}
		// TODO optimize this
		public function insertAnArrayOfSlidesIntoCustomSlidesTable(slides:Array, sectionId:Object, custPresId:int):void{
			
			if ( slides == null || slides.length == 0 ) throw new Error("ERROR");
			
			var k:uint = 0;
			var slide:Object;
			
			var slideInsertStatement:SQLStatement = new SQLStatement();
			slideInsertStatement.sqlConnection = customSQLConnection; 
			
			slideInsertStatement.text = "INSERT OR REPLACE INTO slides";
			
			slide = slides[0];			// TODO can remove below check after a while
			
			if ( ! slide.customSequence || slide.customSequence < 1 || slide.customSequence == "undefined")
			{
				slide.customSequence = 0;
			}
			if ( ! slide.optional_deck_id || slide.optional_deck_id < 1 || slide.optional_deck_id == "undefined")
			{
				slide.optional_deck_id = 0;
			}
			
			if ( slide.sec_slide_id_plus_cust_pres_id == null || slide.sec_slide_id_plus_cust_pres_id == 0 ) 
			{
				//throw new Error("no secSlideIdPlusCustPresId");
				//slide.sec_slide_id_plus_cust_pres_id = 
			}
			
			SlidesUtilities.cleanSlidesMandatoryProperty(slide);
			
			slideInsertStatement.text += " SELECT " + 
				slide.sec_slide_id_plus_cust_pres_id + " AS sec_slide_id_plus_cust_pres_id, " +
				slide.slide_id + " AS slide_id, " + 
				sectionId + " AS section_id, " + 
				custPresId + " AS presentation_id, " + 
				slide.bundle_id  + " AS bundle_id, " + 
				slide.bundle_position + " AS bundle_position, " + 
				slide.sequence + " AS sequence, " + 
				convertToBoolean(slide.locked_to_section) + " AS is_locked, " +  
				convertToBoolean(slide.is_mandatory) + " AS is_mandatory, " +											 
				convertToBoolean(slide.unwanted) + " AS unwanted, " +
				slide.optional_deck_id + " AS optional_deck_id, " +
				slide.customSequence + " AS customSequence, " + 
				//V6
				slide.section_slide_id + " AS section_slide_id ";
			
			for( k = 1; k <slides.length; k++ ) { 
				slide = slides[k]; // TODO can remove below check after a while
				
				SlidesUtilities.cleanSlidesMandatoryProperty(slide);
				
				if ( ! slide.customSequence || slide.customSequence < 1 || slide.customSequence == "undefined")
				{
					slide.customSequence = 0;
				}
				if ( ! slide.optional_deck_id || slide.optional_deck_id < 1 || slide.optional_deck_id == "undefined")
				{
					slide.optional_deck_id = 0;
				}
				if ( slide.sec_slide_id_plus_cust_pres_id == null || slide.sec_slide_id_plus_cust_pres_id == 0 ) throw new Error("no secSlideIdPlusCustPresId");
				
				slideInsertStatement.text += " UNION SELECT " + 
					slide.sec_slide_id_plus_cust_pres_id + " , " +
					slide.slide_id + " , " + 
					sectionId + " , " + 
					custPresId + " , " + 
					slide.bundle_id  + " , " + 
					slide.bundle_position + " , " + 
					slide.sequence + " , " + 
					convertToBoolean(slide.locked_to_section) + ", " + 
					convertToBoolean(slide.is_mandatory) + " , " +											 
					convertToBoolean(slide.unwanted) + " , " +
					slide.optional_deck_id + " , " +
					slide.customSequence + " , " + 
					//V6
					slide.section_slide_id + " "; 
			}
			
			try { 
				slideInsertStatement.execute();
				//trace(" Slide inserted - sec_slide_id_plus_cust_pres_id = " + sec_slide_id_plus_cust_pres_id+ " id " + slide.slide_id);
			}
			catch( error:SQLError ) { 
				trace(" Error: " + slideInsertStatement.text);
				trace(" Details: " + error.details);
				Alert.show("ERROR : text : " + slideInsertStatement.text + " : details : " + error.details,"ERROR");
				throw new Error("error");
			}
		}
		/*public function insertACopiedArrayOfSlidesIntoCustomSlidesTable(slides:Array, sectionId:Object, custPresId:int):void{
		
		var k:uint = 0;
		var slide:Object;
		
		var slideInsertStatement:SQLStatement = new SQLStatement();
		slideInsertStatement.sqlConnection = customSQLConnection; 
		
		slideInsertStatement.text = "INSERT OR REPLACE INTO slides";
		
		for( k = 0; k <slides.length; k++ ) { 
		slide = slides[k];
		
		//slide.sec_slide_id_plus_cust_pres_id = (slide.section_slide_id + (custPresId*10000));
		slideInsertStatement.text = "INSERT OR REPLACE INTO slides";
		
		slideInsertStatement.text += " SELECT " + 
		slide.sec_slide_id_plus_cust_pres_id + " AS sec_slide_id_plus_cust_pres_id, " +
		slide.slide_id + " AS slide_id, " + 
		sectionId + " AS section_id, " + 
		custPresId + " AS presentation_id, " + 
		slide.bundle_id  + " AS bundle_id, " + 
		slide.bundle_position + " AS bundle_position, " + 
		slide.sequence + " AS sequence, " + 
		convertToBoolean(slide.locked_to_section) + " AS is_locked, " + 
		convertToBoolean(slide.is_mandatory) + " AS is_mandatory, " +											 
		convertToBoolean(slide.unwanted) + " AS unwanted";
		
		
		try { 
		slideInsertStatement.execute();
		//trace(" Slide inserted - sec_slide_id_plus_cust_pres_id = " + sec_slide_id_plus_cust_pres_id+ " id " + slide.slide_id);
		}
		catch( error:SQLError ) { 
		trace(" Error: " + slideInsertStatement.text);
		trace(" Details: " + error.details);
		throw new Error("error");
		}
		}
		}*/
		// TODO optimize
		public function reInsertAnArrayOfSlidesIntoSlidesTable(slides:Array,custPresId:int):void{
			var k:uint = 0;
			var slide:Object;
			
			var slideInsertStatement:SQLStatement = new SQLStatement();
			slideInsertStatement.sqlConnection = customSQLConnection; 
			
			for( k = 0; k <slides.length; k++ ) { 
				slide = slides[k];
				
				SlidesUtilities.cleanSlidesMandatoryProperty(slide);
				
				// TODO optimize
				slideInsertStatement.text = "UPDATE slides";
				slideInsertStatement.text += " SET " + 
					//slide.slide_id + " AS slide_id, " + 
					// TODO -- hard coding this for now
					// "100" + " AS section_id, " + 
					// presentationId + " AS presentation_id, " + 
					//" sec_slide_id_plus_cust_pres_id = " + (slide.section_slide_id + ( custPresId*10000 )) + ", " +  // NOTE section_slide_id is useless on customized decks
					" bundle_id = " + slide.bundle_id  + ", " + 
					" bundle_position = " + slide.bundle_position + ", " +  
					" sequence = " + slide.sequence + ", " +  
					" is_locked = " + convertToBoolean(slide.locked_to_section) + ", " +  
					" is_mandatory = " + convertToBoolean(slide.is_mandatory) + ", " + 											 
					" unwanted = " + convertToBoolean(slide.unwanted) + ", " +
					" customSequence = " + int(slide.customSequence) +
					" WHERE " +
					" sec_slide_id_plus_cust_pres_id = " + slide.sec_slide_id_plus_cust_pres_id;
				
				try { 
					slideInsertStatement.execute();
					//trace(" Slide inserted - wanted = " + convertToBoolean(slide.unwanted) + " id " + slide.slide_id);
				}
				catch( error:SQLError ) { 
					trace(" Error: " + slideInsertStatement.text);
					trace(" Details: " + error.details);
					Alert.show("ERROR : text : " + slideInsertStatement.text + " : details : " + error.details,"ERROR");
					throw new Error("error");
				}
			}
		}
		public function reInsertASingleSlideIntoSlidesTableBySecSlideId(slide:Object, sqlConnection:SQLConnection):void{
			
			SlidesUtilities.cleanSlidesMandatoryProperty(slide);
			
			var slideInsertStatement:SQLStatement = new SQLStatement();
			slideInsertStatement.sqlConnection = sqlConnection;
			
			var specialUnwanted:Boolean;
			if ( sqlConnection == systemSQLConnection)
			{
				specialUnwanted = slide.unwanted;
			}
			else
			{
				specialUnwanted = slide.is_mandatory;
			}
			
			slideInsertStatement.text = "UPDATE slides";
			
			slideInsertStatement.text += " SET " + 
				" section_id = " + slide.section_id + ", " +
				" bundle_id = " + slide.bundle_id  + ", " + 
				" bundle_position = " + slide.bundle_position + ", " +  
				" sequence = " + slide.sequence + ", " +  
				" is_locked = " + convertToBoolean(slide.locked_to_section) + ", " +  
				" is_mandatory = " + convertToBoolean(slide.is_mandatory) + ", " + 											 
				" unwanted = " + convertToBoolean(specialUnwanted) + 
				" WHERE " +
				" section_slide_id = " + slide.section_slide_id;
			
			try { 
				slideInsertStatement.execute();
				//trace(" Slide inserted - wanted = " + convertToBoolean(slide.unwanted) + " id " + slide.slide_id);
			}
			catch( error:SQLError ) { 
				trace(" Error: " + slideInsertStatement.text);
				trace(" Details: " + error.details);
				throw new Error("error");
			}
		}
		public function reInsertASingleCustomSlideIntoSlidesTableByCustSecSlideId(slide:Object,secSlideIdPlusCustPredId:uint):void{
			
			SlidesUtilities.cleanSlidesMandatoryProperty(slide);
			
			var slideInsertStatement:SQLStatement = new SQLStatement();
			slideInsertStatement.sqlConnection = customSQLConnection;
			
			var specialUnwanted:Boolean;
			specialUnwanted = slide.is_mandatory;
			
			if ( ! slide.customSequence || slide.customSequence < 1 || slide.customSequence == "undefined")
			{
				slide.customSequence = 0;
			}
			if ( ! slide.optional_deck_id || slide.optional_deck_id < 1 || slide.optional_deck_id == "undefined")
			{
				slide.optional_deck_id = 0;
			}
			
			slideInsertStatement.text = "UPDATE slides";
			
			slideInsertStatement.text += " SET " + 
				" section_id = " + slide.section_id + ", " +
				" bundle_id = " + slide.bundle_id  + ", " + 
				" bundle_position = " + slide.bundle_position + ", " +  
				" sequence = " + slide.sequence + ", " +  
				" is_locked = " + convertToBoolean(slide.locked_to_section) + ", " +  
				" is_mandatory = " + convertToBoolean(slide.is_mandatory) + ", " + 											 
				" unwanted = " + convertToBoolean(specialUnwanted) + ", " +
				" optional_deck_id = " + slide.optional_deck_id + ", " +
				" customSequence = " + slide.customSequence +
				" WHERE " +
				" sec_slide_id_plus_cust_pres_id = " + secSlideIdPlusCustPredId;
			
			try { 
				slideInsertStatement.execute();
				//trace(" Slide inserted - wanted = " + convertToBoolean(slide.unwanted) + " id " + slide.slide_id);
			}
			catch( error:SQLError ) { 
				trace(" Error: " + slideInsertStatement.text);
				trace(" Details: " + error.details);
				throw new Error("error");
			}
		}
		
		private function firstDeleteAlreadyExistingSlides(slides:Array,presentationId:int, sqlConnection:SQLConnection):void{
			var k:uint = 0;
			var slide:Object;
			
			var dropStatement:SQLStatement = new SQLStatement();
			dropStatement.sqlConnection = sqlConnection; 
			
			for( k = 0; k <slides.length; k++ ) { 
				slide = slides[k];
				
				// CUSTOM
				dropStatement = new SQLStatement();
				dropStatement.text = "DELETE FROM  slides WHERE slide_id = "  + slide.slide_id + " AND presentation_id = " + slide.presentation_id;
				dropStatement.sqlConnection = customSQLConnection;
				try { 
					dropStatement.execute();
				}
				catch(error:SQLError) { 
					trace(" Error: " + dropStatement.text );
					trace(" Message: " + error.message + " && Details: " + error.details);
					// Fail silently - there may not be such a presentation id
				}				
			}
		}
		
		
		
		//=====================================================================================================
		// INSERT OPTIONAL DECKS
		//=====================================================================================================
		
		public function insertRelationalMappingsBetweenPresentationsAndOptionalDecks(optionalDecks:Array,presentationId:int):void{
			var insertStatement:SQLStatement = new SQLStatement();
			insertStatement.sqlConnection = this.systemSQLConnection; 
			
			for ( var i:uint = 0 ; i < optionalDecks.length; i++)
			{
				var optionalDeck:Object = optionalDecks[i];
				
				insertStatement.text = "INSERT OR REPLACE INTO optional_deck_ids_relation_to_presentation_ids";
				
				insertStatement.text += " SELECT " + 
					optionalDeck.core_optional_connection_id + " AS core_optional_connection_id, " +		
					optionalDeck.optional_deck_id + " AS optional_deck_id, " +
					presentationId + " AS presentation_id ";
				
				try { 
					insertStatement.execute();
				}
				catch( error:SQLError ) { 
					trace(" Error: " + insertStatement.text);
					trace(" Details: " + error.details);
					Alert.show("ERROR : text : " + insertStatement.text + " : details : " + error.details,"ERROR");
					throw new Error("error");
				}
			}
		}
		public function insertCoreOptionalConnectionsArray(coreOptionalConnections:Array):void{
			var insertStatement:SQLStatement = new SQLStatement();
			insertStatement.sqlConnection = this.systemSQLConnection; 
			
			for ( var i:uint = 0 ; i < coreOptionalConnections.length; i++)
			{
				var coreOptionalConncetion:Object = coreOptionalConnections[i];
				
				insertStatement.text = "INSERT OR REPLACE INTO optional_deck_ids_relation_to_presentation_ids";
				
				insertStatement.text += " SELECT " + 
					coreOptionalConncetion.core_optional_connection_id + " AS core_optional_connection_id, " +		
					coreOptionalConncetion.optional_deck_id + " AS optional_deck_id, " +
					coreOptionalConncetion.core_deck_id + " AS presentation_id ";
				
				try { 
					insertStatement.execute();
				}
				catch( error:SQLError ) { 
					trace(" Error: " + insertStatement.text);
					trace(" Details: " + error.details);
					Alert.show("ERROR : text : " + insertStatement.text + " : details : " + error.details,"ERROR");
					throw new Error("error");
				}
			}
		}
		public function insertCoreOptionalConnectionsArrayFromInsidePresentations(coreOptionalConnections:Array,coreDeckId:uint):void{
			var insertStatement:SQLStatement = new SQLStatement();
			insertStatement.sqlConnection = this.systemSQLConnection; 
			
			for ( var i:uint = 0 ; i < coreOptionalConnections.length; i++)
			{
				var coreOptionalConncetion:Object = coreOptionalConnections[i];
				
				insertStatement.text = "INSERT OR REPLACE INTO optional_deck_ids_relation_to_presentation_ids";
				
				insertStatement.text += " SELECT " + 
					coreOptionalConncetion.core_optional_connection_id + " AS core_optional_connection_id, " +		
					coreOptionalConncetion.optional_deck_id + " AS optional_deck_id, " +
					coreDeckId + " AS presentation_id ";
				
				try { 
					insertStatement.execute();
				}
				catch( error:SQLError ) { 
					trace(" Error: " + insertStatement.text);
					trace(" Details: " + error.details);
					Alert.show("ERROR : text : " + insertStatement.text + " : details : " + error.details,"ERROR");
					throw new Error("error");
				}
			}
		}
		public function insertAnArrayOfOptionalDecks(optionalDecks:Array, sqlConnection:SQLConnection):void{
			
			var i:uint = 0;
			var j:uint = 0;
			var k:uint = 0;
			var optionalDeck:Object;
			var optionalDeckInsertStatement:SQLStatement = new SQLStatement();
			optionalDeckInsertStatement.sqlConnection = sqlConnection; 
			
			for( i = 0; i < optionalDecks.length; i++ ) { 
				
				optionalDeck = optionalDecks[i];
				
				optionalDeckInsertStatement.text = "INSERT OR REPLACE INTO optional_decks";		
				optionalDeckInsertStatement.text += " SELECT " + 
					optionalDeck.id + " AS optional_deck_id, '" + 
					escapeSingleQuotes(optionalDeck.deck_name) + "' AS deck_name";
				
				if( optionalDeck.sections && optionalDeck.sections.length > 0 ) { 
					var section:Object;
					var sectionInsertStatement:SQLStatement = new SQLStatement();
					sectionInsertStatement.sqlConnection = sqlConnection; 
					
					for( j = 0; j < optionalDeck.sections.length; j++ ) { 
						section = optionalDeck.sections[j];
						
						sectionInsertStatement.text = "INSERT OR REPLACE INTO optional_sections";
						
						sectionInsertStatement.text += " SELECT " + 
							section.id + " AS section_id, " + 
							optionalDeck.id + " AS optional_deck_id, '" + 
							escapeSingleQuotes(section.section_name) + "' AS section_name, " + 
							section.sequence + " AS sequence";
						
						if( section.slides && section.slides.length > 0 ) { 
							var slide:Object = section.slides[0];
							var slideInsertStatement:SQLStatement = new SQLStatement();
							slideInsertStatement.sqlConnection = sqlConnection; 
							slideInsertStatement.text = "INSERT OR REPLACE INTO optional_slides";
							slideInsertStatement.text += " SELECT " + 
								slide.slide_id + " AS slide_id, " + 
								section.id + " AS section_id, " + 
								optionalDeck.id + " AS optional_deck_id, " + 
								slide.section_slide_id + " AS section_slide_id, " +
								slide.bundle_id  + " AS bundle_id, " + 
								slide.bundle_position + " AS bundle_position, " + 
								slide.sequence + " AS sequence, " + 
								"0 AS unwanted";				
							for( k = 1; k < section.slides.length; k++ ) { 
								slide = section.slides[k];
								slideInsertStatement.text += " UNION SELECT " + 
									slide.slide_id + " , " + 
									section.id + " , " + 
									optionalDeck.id + " , " + 
									slide.section_slide_id + " , " +
									slide.bundle_id  + " , " + 
									slide.bundle_position + " , " + 
									slide.sequence + " , " + 
									"0";				
							}// close for k
							try { 
								slideInsertStatement.execute();
							}
							catch( error:SQLError ) { 
								trace(" Error: " + slideInsertStatement.text);
								trace(" Details: " + error.details);
								Alert.show("ERROR : text : " + slideInsertStatement.text + " : details : " + error.details,"ERROR");
								throw new Error("error");
							}// done inserting slides
							try { 
								sectionInsertStatement.execute();
								trace(" Sections In Optional Decks inserted successfully! ");
							}
							catch( error:SQLError ) { 
								trace(" Error: " + sectionInsertStatement.text);
								trace(" Details: " + error.details);
								Alert.show("ERROR : text : " + slideInsertStatement.text + " : details : " + error.details,"ERROR");
								throw new Error("error");
							}	
						}// close for j
					}
					
				}// close if( optionalDeck.sections && optionalDeck.sections.length > 0 ) { 
				try { 
					optionalDeckInsertStatement.execute();
					trace(" Optional deck inserted successfully! ");
				}
				catch( error:SQLError ) { 
					trace(" Error: " + optionalDeckInsertStatement.text);
					trace(" Details: " + error.details);
					Alert.show("ERROR : text : " + optionalDeckInsertStatement.text + " : details : " + error.details,"ERROR");
					throw new Error("error");
				}
			}// close for i 
		}
		
		public function insertATitleSlide(titleSlide:Object):void
		{
			/*
			presentation_id
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
			*/
			var insertStatement:SQLStatement = new SQLStatement();
			insertStatement.sqlConnection = this.customSQLConnection; 
			
			insertStatement.text = "INSERT OR REPLACE INTO title_slide";
			
			insertStatement.text += " SELECT " + 
				titleSlide.custom_presentation_id + " AS custom_presentation_id, '" +		
				titleSlide.date_string + "' AS date_string, " +
				titleSlide.date_x + " AS date_x, " +
				titleSlide.date_y + " AS date_y, " +
				titleSlide.date_size + " AS date_size, " +
				titleSlide.date_color + " AS date_color, '" +
				escapeSingleQuotes(titleSlide.title_string) + "' AS title_string, " +
				titleSlide.title_x + " AS title_x, " +
				titleSlide.title_y + " AS title_y, " +
				titleSlide.title_color + " AS title_color, " +
				titleSlide.title_size + " AS title_size, " +
				titleSlide.chosen_timestamp + " AS chosen_timestamp ";
			
			try { 
				insertStatement.execute();
				trace(" title slide inserted successfully");
			}
			catch( error:SQLError ) { 
				trace(" Error: " + insertStatement.text);
				trace(" Details: " + error.details);
				throw new Error("error");
			}
			
		}
		
		//====================================================================================================================
		// RESOURCES
		//====================================================================================================================
		
		/*
		resources table
		------------------
		" id INTEGER PRIMARY KEY NOT NULL, " +
		" brand_id INTEGER," +	
		" brand_name TEXT," +	
		" deck_id INTEGER," +	
		" deck_name TEXT," +	
		" url TEXT," +	 
		" html_title TEXT," +
		" stripped_title TEXT," +
		" resources_title TEXT" +		// hey you never know !		
		*/
		
		public function insertAnArrayOfResourcesByBrandOrDeck(byBrand:Boolean, brandOrDeckResourcesArray:Array ):void{
			
			var i:uint = 0;
			var brandOrDeck:Object;
			var brandOrDeckResource:Object;
			var resources:Array;
			
			var brandId:int;
			var brandName:String;
			var deckId:int;
			var deckName:String;
			var deckResourcesTitle:String;
			
			var resourceInsertStatement:SQLStatement = new SQLStatement();
			resourceInsertStatement.sqlConnection = this.systemSQLConnection; 
			resourceInsertStatement.text = "INSERT OR REPLACE INTO resources ";	
			
			for( i = 0; i < brandOrDeckResourcesArray.length; i++ ) { 
				
				brandOrDeckResource = brandOrDeckResourcesArray[i];
				brandOrDeck = ( byBrand ? brandOrDeckResource.brand : brandOrDeckResource.deck );
				resources = brandOrDeckResource.resources;
				
				if ( byBrand )
				{
					brandId = brandOrDeck.id;
					brandName = brandOrDeck.slug;
					deckId = 0;
					deckName = "";
					deckResourcesTitle = "";
					
				}else{
					brandId = 0;
					brandName = "";
					deckId = brandOrDeck.id;
					deckName = brandOrDeck.deck_name;
				}
				
				if ( ! brandOrDeck.hasOwnProperty("order") )
				{
					brandOrDeck.order = 0;
				}
				if ( i == 0 ) 
				{
					resourceInsertStatement.text += generateInsertStatementForResources(false, resources, brandId, brandName, deckId, deckName, deckResourcesTitle );
				}else{
					resourceInsertStatement.text += generateInsertStatementForResources(true, resources, brandId, brandName, deckId, deckName, deckResourcesTitle );
				}
			}
			
			try { 
				resourceInsertStatement.execute();
			}
			catch( error:SQLError ) { 
				trace(" Error: " + resourceInsertStatement.text);
				trace(" Details: " + error.details);
				Alert.show("ERROR : text : " + resourceInsertStatement.text + " : details : " + error.details,"ERROR");
				throw new Error("error");
			}
		}
		
		private function generateInsertStatementForResources( useUnionSelect:Boolean, resources:Array, brandId:int, brandName:String, deckId:int, deckName:String , deckResourcesTitle:String):String
		{
			var resource:Object;
			var insertString:String = "";
			var i:int;
			
			if ( ! useUnionSelect )
			{
				resource = resources[0];
				insertString += " SELECT " + 
					resource.id + " AS id, " +
					brandId + " AS brand_id, '" +
					escapeSingleQuotes(brandName) + "' AS brand_name, " +
					deckId + " AS deck_id, '" +
					escapeSingleQuotes(deckName) + "' AS deck_name, '" +
					escapeSingleQuotes(resource.url) + "' AS url, '" + 
					escapeSingleQuotes(resource.html_title) + "' AS html_title, '" +
					escapeSingleQuotes(resource.stripped_title) + "' AS stripped_title, '" +
					escapeSingleQuotes(deckResourcesTitle) + "' AS resources_title, " + 
					resource.order + " AS refNumber ";
			}
			
			for( i = ( useUnionSelect ? 0 : 1 ); i < resources.length; i++ ) { 
				
				resource = resources[i];
				insertString += " UNION SELECT " + 
					resource.id + " , " +
					brandId + " , '" +
					escapeSingleQuotes(brandName) + "' , " +
					deckId + " , '" +
					escapeSingleQuotes(deckName) + "' , '" +
					escapeSingleQuotes(resource.url) + "' , '" + 
					escapeSingleQuotes(resource.html_title) + "' , '" +
					escapeSingleQuotes(resource.stripped_title) + "' , '" +
					escapeSingleQuotes(deckResourcesTitle) + "'  ," +
					resource.order + " ";
			}
			return insertString;
		}
		
		public function getResourcesByBrandId ( brandId:int ) : Array{
			var returnArray:Array = getWhere( systemSQLConnection, "resources", "brand_id", brandId );
			return returnArray;
		}
		public function getResourcesByDeckId ( deckId:int ) : Array{
			var returnArray:Array = getWhere( systemSQLConnection, "resources", "deck_id", deckId );
			return returnArray;
		}
		
		public function getAllResources( sqlConnection:SQLConnection ):Array
		{
			var result:SQLResult;
			var resultArray:Array = new Array();
			var selectStatement:SQLStatement = new SQLStatement();
			selectStatement.sqlConnection = sqlConnection;
			
			selectStatement.text = "SELECT * FROM resources";
			
			try { 
				selectStatement.execute();
				
				result = selectStatement.getResult();
				
				if( result.data ) { 
					for( var i:uint = 0; i < result.data.length; i++ ) { 
						resultArray[resultArray.length] = result.data[i];
					}
				}
			}
			catch( error:SQLError ) { 
				trace(" Error: " + selectStatement.text );
				trace(" Message: " + error.message + " && Details: " + error.details);
				Alert.show("ERROR : text : " + selectStatement.text + " : details : " + error.details,"ERROR");
				throw new Error("error");
			}
			return resultArray;
		}
		
		//====================================================================================================================
		// EXTERNAL APPS
		//====================================================================================================================
		
		public function insertAnExternalAppIntoExternalAppsTable(appName:String):void{
			
			var appInsertStatement:SQLStatement = new SQLStatement();
			appInsertStatement.sqlConnection = this.systemSQLConnection; 
			appInsertStatement.text = "INSERT OR REPLACE INTO external_apps ";	
			
			appName = appName.split(" ").join(""); 
			
			appInsertStatement.text += " SELECT '" + 
				escapeSingleQuotes(appName) + "' AS app_name ";	
			
			try { 
				appInsertStatement.execute();
			}
			catch( error:SQLError ) { 
				trace(" Error: " + appInsertStatement.text);
				trace(" Details: " + error.details);
				Alert.show("ERROR : text : " + appInsertStatement.text + " : details : " + error.details,"ERROR");
				throw new Error("error");
			}
		}
		
		
		
		
		
		
		//====================================================================================================================
		// V6
		// EITHER OR COMBINATIONS
		//====================================================================================================================
		public function insertEitherOrCombinationsFromPresentationsData( presentationsData:Object ):void
		{
			
			var i:uint = 0;
			var j:uint = 0;
			var k:uint = 0;
			
			trace("inserting either or combinations data...");
			
			if( presentationsData.Presentations.length > 0 ) { 
				var presentation:Object;
				for( i = 0; i < presentationsData.Presentations.length; i++ ) { 
					
					presentation = presentationsData.Presentations[i];
					
					var comboInsertStatement:SQLStatement = new SQLStatement();
					comboInsertStatement.sqlConnection = systemSQLConnection;
					
					if ( presentation.combinations && presentation.combinations.length  > 0 )
					{
						for ( j = 0; j < presentation.combinations.length; j++)
						{
							var combo:Object = presentation.combinations[j];
							
							comboInsertStatement.text = "INSERT OR REPLACE INTO either_or_combinations";
							
							comboInsertStatement.text += " SELECT " + 
								presentation.id + " AS presentation_id, '" + 
								combo.object_one_content_type[0].name +  "' AS object_one_content_type, " +
								combo.object_one_object_id + " AS object_one_object_id, '" +
								combo.object_two_content_type[0].name +  "' AS object_two_content_type, " +
								combo.object_two_object_id + " AS object_two_object_id, " + 
								convertToBoolean(combo.required) + " AS required ";
							
							try { 
								comboInsertStatement.execute();
							}
							catch( error:SQLError ) { 
								trace(" Error: " + comboInsertStatement.text);
								trace(" Details: " + error.details);
								Alert.show("Error : " + error.details);
							}
						}
					}
				}
			}
		}
		//====================================================================================================================
		// UPDATE
		//====================================================================================================================
		
		public function updateWhere(sqlConnection:SQLConnection, tableName:String, columnName:String, value:String, whereColumn:String, valueColumn:Object):void	// changed value column to type object from string 03/18
		{
			var updateStatement:SQLStatement = new SQLStatement();
			updateStatement.sqlConnection = sqlConnection;
			
			updateStatement.text = "UPDATE " + tableName + " SET " + columnName + "=" + valueToSQLString(value) + " WHERE " + whereColumn + "='" + valueColumn + "'";
			
			try { 
				updateStatement.execute();
				trace(" UPDATED in " + updateStatement.sqlConnection.toString() + ": " + updateStatement.text);
			}
			catch( error:SQLError ) { 
				trace(" Error: " + updateStatement.text + " | " + error.message );
			}
		}
		
		//====================================================================================================================
		// UTILITY FUNCTIONS
		//====================================================================================================================
		
		public function valueToSQLString(val:*):String
		{
			if( val == null || val == "null" || val == "NULL" ) return "NULL";
			
			switch( typeof(val) ) { 
				case "boolean" : 
					if( val == true ) { 
						return '1';
					}
					else if( val == false ) { 
						return '0';
					}
					else { 
						return val;
					}
					break;
				case "number" : 
					return "'" + val + "'";
					break;
				case "string" : 
					if( val == "null" || val == "NULL" ) { 
						return "NULL";
					}
					if( val == "false" || val == "FALSE" ) { 
						return '0';
					}
					if( val == "true" || val == "TRUE" ) { 
						return '1';
					}
					return "'" + val + "'";
					break;
				case "undefined" : 
					return "NULL";
					break;
				default : 
					break;
			}
			
			return "'" + val + "'";
		}
		
		private function escapeSingleQuotes(val:String):String
		{
			if ( val )
			{
				val = val.split("'").join("''");
			}
			return val;
			
			
			
			// dont work :/
			//			var r:RegExp = /\'/g;
			//			
			//			return val.replace(r, "''");
		}
		
		private function convertToBoolean(val:*):uint
		{
			switch(val) { 
				case 0 : 
				case false : 
				case 'false' : 
				case 'FALSE' : 
					return 0;
					break;
				case 1 : 
				case true : 
				case 'true' : 
				case 'TRUE' : 
					return 1;
					break;
				default : 
					break;
			}
			return null;
		}
		
		
		//====================================================================================================================
		// UTILITY FUNCTIONS
		//====================================================================================================================
		
		public function getSlideNotesFromSlideId(slide_id:int):String{
			var slidesArray:Array = getWhere(systemSQLConnection,"slides_alone","slide_id",slide_id);
			var slide:Object = slidesArray[0];
			var notes:String = slide.notes as String;
			//notes = HTMLFormatNotesText(notes);
			if( notes == null || notes == "null" || notes == "NULL" || notes == "Null" ) notes = 'No notes.';
			return notes;
		}
		
		public function presentationIsCustomPresentation(presentationObject:Object):Boolean
		{
			if ( presentationObject.hasOwnProperty("custom_presentation_id") && (presentationObject.custom_presentation_id as int) > 0 )
			{
				return true; 
			}else{ 
				return false;
			}			
		}
		
		public function getNewCustomPresentationIdAndCreatedDate(presentationObject:Object, forCopiedDeck:Boolean=false):void{
			//get all the cutom presentations that we have
			// take the highest id value
			// +1
			var allTheCustomPresentations:Array = getAllPresentationsByDate(customSQLConnection);
			if ( ! allTheCustomPresentations || allTheCustomPresentations.length < 1 )
			{
				presentationObject.custom_presentation_id = 1;								
			}else{
				
			
			var highestId:uint = 0;
			for ( var i: uint = 0 ; i< allTheCustomPresentations.length; i++)
			{
				var customPresentation:Object = allTheCustomPresentations[i];
				var id:int = customPresentation.custom_presentation_id as int;
				if ( id >= highestId)
				{
					highestId = id;
				}
			}
			presentationObject.custom_presentation_id = highestId+1;
			
			}
			
			
			//=========================================================
			// V 6.0 - create a GUID or a UUID that is unique, immutable and generated on the client side
			//=========================================================
			
			// V6TODO
			//generate guid here and put it on !
			var guid:String = UIDUtil.createUID();
			if ( presentationObject.guid == null || presentationObject.guid.length < 3 || forCopiedDeck )
			{
				presentationObject.guid = guid;				
			}

			putTodaysDateAsCreatedDate(presentationObject);
			
		}
		
		public function getNewCustomPresentationIdForPulledCustomDeck():int{
			//get all the cutom presentations that we have
			// take the highest id value
			// +1
			var allTheCustomPresentations:Array = getAllPresentationsByDate(customSQLConnection);
			if ( ! allTheCustomPresentations || allTheCustomPresentations.length < 1 )
			{
				return 1;								
			}	
				
				var highestId:int = 0;
				for ( var i: uint = 0 ; i< allTheCustomPresentations.length; i++)
				{
					var customPresentation:Object = allTheCustomPresentations[i];
					var id:int = customPresentation.custom_presentation_id as int;
					if ( id >= highestId)
					{
						highestId = id;
					}
				}
			
				return highestId+1;
			
		}
		
		private function putTodaysDateAsCreatedDate(presentationObject:Object):void{
			var today:Date = new Date();
			var dateFormatter:DateFormatter = new DateFormatter();
			dateFormatter.formatString = "YYYY-MM-DD";				
			var dateString:String = dateFormatter.format(today);
			//V6 we need more than just the date we need the time as well
			var time:Number = today.time;
			//presentationObject.date_created = dateString;
			presentationObject.date_created = time.toString();
		}
		
		public function stripHTMLFormatting(notes:String):String{
			var myPattern: RegExp =/<[^>]*>/g 
			notes = notes.replace(myPattern,"");
			notes = notes.split("&nbsp;").join("");
			return notes;
		}
		
		
		
		
		
	}
}

