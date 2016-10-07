#Scholarly Tracking Project
#Author: Evan Sprague

The scholarlyTracking.pl script uses the perl module XML::LibXML, to install use the following terminal commands

	sudo cpan XML::LibXML

The script can be run in a command prompt terminal by moving to the directory where the program is located and running it with the following command

	perl scholarlyTracking5.0.pl 

In the section of the script labeled FILE LOCATIONS, there are there locations of note.

	$xmlFile - is the incoming xml data
	$authFile - is the institutional author list tab delimited with the format 'IndexNum LastName FirstName MiddleName'
	$outputFile - the name of the xml file created by the script

$authFile must be created as a tab delimited file with each author given a unique identifier number in the first column. The script can not currently identify variations of names with suffixes (Jr, III, etc..,) so the author file should include name variations with and without the suffix. The script also dose does not search for names with and without diacritics (ñ, Ö, etc…), so variations of names with diacritics and a normalized version will need to be added to the author list. Each column should contain the following

	UniqueIndexNum	LastName	FirstName	MiddleName(optional)





