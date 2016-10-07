#!/usr/bin/env perl  

# Scholarly Tracking Project 5.0
# This versions goal is to clean up the script for sharing with other libraries

# Author: Evan Sprague

use strict;
use warnings; 
use XML::LibXML;

# This confims the user has XML::LibXML installed before running the program
eval "use XML::LibXML;1" or die "or need to install XML::LibXML to run this 
  program.";

################################################################################
#                         FILE LOCATIONS                                       #
################################################################################

# Declares the file name of the XML file
my $xmlFile = '15-16_Q3_Report_RawData.xml';

# Declares a file for the list of authors
my $authFile = 'Faculty_List_with_2015_End_Dates_Tab_Separated.txt';

# Declares a file location for the program to save to
my $outputFile = 'scholarlyTrackingTest4.0.3.xml';

################################################################################
#                         XML PARSER                                           #
################################################################################

# Creates a parser
my $parser = XML::LibXML->new();

# Parses file and stores into $doc
my $doc = $parser->parse_file($xmlFile);

################################################################################
#                         AUTHOR LIST                                          #
################################################################################

# Initializes a counter at 0, to count the how many authors the script checks
my $SearchedCount = 0;
my $FoundCount = 0;

# Creates arrays to store the Author Info

# Opens the file of authors
open (my $FH, "<", "$authFile") or die "Cannot open $authFile for read: $!";
# Reads each line of the author file, and fills the array with each line
my @authArray = <$FH>;
# Closes the author list file
close ($FH) or die "Cannot close $authFile: $!";

    my %Ln_index;       #Array of author last names
    my %Fn_index;       #Array of author first names
    my %Mn_index;       #Array of author middle names
    my %Dept_index;     #Array of departments
    my %Sdate_index;    #Array of Start Dates
    my %Tdate_index;    #Array of Termination Dates
    my %FM_index;       #Array of first and middle name initials

    my $firstTempIn;
    my $midTempIn;

# This goes though each line of the author array and compiles the following code
foreach (@authArray) {
    # Sets $authorInfo as the current line of the author array
    my $authorInfo = $_;
    # Removes any new line characers (\n) curently stored in $authorInfo
    chomp ($authorInfo); 
    # DEBUG: Prints out $authorInfo for testing purposes
    #print "$authorInfo\n";
    
    # Sends each author to be searched
    my (@splitAuthorInfo) = auth_split($authorInfo);
    
    # Fills in author info arrays
    $Ln_index{$splitAuthorInfo[0]}      = $splitAuthorInfo[1];
    $Fn_index{$splitAuthorInfo[0]}      = $splitAuthorInfo[2];
    $Mn_index{$splitAuthorInfo[0]}      = $splitAuthorInfo[3];
    $Dept_index{$splitAuthorInfo[0]}    = $splitAuthorInfo[4];
    $Sdate_index{$splitAuthorInfo[0]}   = $splitAuthorInfo[5];
    $Tdate_index{$splitAuthorInfo[0]}   = $splitAuthorInfo[6];

    # The following code fills in the FM_index array if a middle name is avaible
    if ($Mn_index{$splitAuthorInfo[0]} eq ""){
        $FM_index{$splitAuthorInfo[0]}  = "";
    }
    else{
        $firstTempIn = substr $Fn_index{$splitAuthorInfo[0]}, 0, 1;
        $midTempIn   = substr $Mn_index{$splitAuthorInfo[0]}, 0, 1;
        $FM_index{$splitAuthorInfo[0]}  = "$firstTempIn$midTempIn";
    }
}
    # Used for testing the auhtor index arrays
    #print "$FM_index[3] $Ln_index[3]\n";
################################################################################
#                         SEARCHING XML DOC                                    #
################################################################################

# Var's used in this section of code
# authoChildNode used to temporarily store an author from XML data
my $authChildNode;

# The following code cycle though all authors in XML data
my $query  ="//author/style";
foreach my $styleNode ($doc->findnodes($query)) {

    # Counts each XML author the script checks
    $SearchedCount = $SearchedCount+1;
    

    $authChildNode      = $styleNode->lastChild;
#    $authChildNode      =~ s/[[:punct:]]//g ;   # Removes punctuation
    $authChildNode      =~ s/(?!-)[[:punct:]]/ /g ;# Removes punctuation, except
                                                    # for -
    $authChildNode      =~ s/\s+$//;     # Trims end
    $authChildNode      =~ s/^\s+//;     # Trims beginning
    $authChildNode      =~ s/\s+/|/g;    # Removes all whitespace adds |
    #$authChildNode      =~ s/\s+//g;    # Removes whitespace
    # DEBUG: Used to test the codes ability to identify a author in the XML file
    #print "$authChildNode\n";

    my %lastN_returnValues = lastN_search($authChildNode, 
        \%Ln_index, \%Fn_index);
    my @firstN_returnValues = firstN_Search($authChildNode, 
        \%lastN_returnValues, \%Fn_index);
    #print "$lastN_returnValues\n";



    if ($firstN_returnValues[0] eq "found"){
        $FoundCount = $FoundCount+1;
        print "Found One\n";
        
        $styleNode->setAttribute('face'=> "bold");

# The following code can be used to add author departments to the EndNote feild
#  custom3, if departments are included in the 4th column of the author list.
#  This code is still a work in progress
    #    my ($dept) = $styleNode->parentNode;# author Node
    #    ($dept) = $dept->parentNode;        # authors Node
    #    ($dept) = $dept->parentNode;        # contibutors Node
    #    ($dept) = $dept->parentNode;        # record Node
        # This moves down the record to the custom3 feild
    #    ($dept) = $dept->getChildrenByLocalName("custom3");
    #    ($dept) = $dept->lastChild;         # custom3/style Node
    #    ($dept) = $dept->lastChild;         # style/text() Node
        # This sets the custom3 value (department) with the given string
    #    $dept->appendData("$Dept_index{$firstN_returnValues[1]} \n");
    }
    else{


        print "SEARCHING\n"; #Failed to locate an institutional author


    }
}

################################################################################
#                         CREATE OUTPUT FILES                                  #
################################################################################
# Dispalys in terminal how many authors searched in XML file
print "$SearchedCount Authors searched\n";
print "$FoundCount possible matches located\n";

#Writes to/creates outputfile
$doc->toFile($outputFile);

################################################################################
################################################################################
#                         SUBROUTINES                                          #
################################################################################
################################################################################

################################################################################
#                         AUTHOR LIST SPLITING SUBROUTINE                      #
################################################################################

# This subroutine splits the author information into individual elements and
# passes those elements back to be searched
sub auth_split {
     
    # Places all the author information into the var $wholeAuthor
    my ($wholeAuthor) = @_;
     
    # DEBUG: This prints out $wholeAuthor for testing purposes
    #print "$wholeAuthor\n";
     
    # Places each author element into an array, using tab (\t) to determine each
    # element. Elements are as follows:
    #     [0]indexNum [1]Last_Name [2]First_Name [3]Middle_Name
    my @authInfoArray = split("\t", $wholeAuthor);
#    my @authInfoArray = split('|', $wholeAuthor);
     
    # DEBUG: Used for testing purposes to confirm that the elements are being
    #        placed in the coreect locations in array
    #print "$authInfoArray[0]\n";
     
    # Places the 1st author element (author's last name)
    # into the variable $lastName, and so on...
    my $indexNum  = $authInfoArray[0];
    my $lastName  = $authInfoArray[1];
    my $firstName = $authInfoArray[2];
    my $midName   = $authInfoArray[3];
    my $department= $authInfoArray[4];
    my $startDate = $authInfoArray[5];
    my $termDate  = $authInfoArray[6];
    
    # Used for testing Author spliting subroutine
    #print "$lastName\n";

    # Returns author's name, each part as its own element
    return ($indexNum, $lastName, $firstName, $midName, $department,
       $startDate, $termDate);
}
################################################################################
#                         SEARCHING SUBROUTINES                                #
################################################################################

sub lastN_search{

    my %XMLAuthorHash;         #XML author name split into parts
    my $name;                  #XML author name being checked
    my $ln;                    #LastName of index author currently being checked
    my $id;                    #IndexNum of index author currently being checked
    my %posResults;            #Index number being returned if positive result
    my $authChildNodeSub        = $_[0];    #Author from XML file
    my @XMLAuth = split(/\|/, $authChildNodeSub); #Array of XML author name
    my %Ln_indexSub             = %{$_[1]}; #Last Name Author Index
    my %Fn_indexSub             = %{$_[2]}; #First Name Author Index

    # Palces name into hash so we can search key
    foreach $name(@XMLAuth){
        $XMLAuthorHash{$name}=$name; 
    }

    # Compares XML author to all of last name index
    while (($id,$ln) = each (%Ln_indexSub)){
        if (exists($XMLAuthorHash{$ln})){
            $posResults{$id}=$id;
        }        
    }
    return (%posResults); #Return nothing, could not find
}

sub firstN_Search{

    #my %posResults;             #NOT USED???
    my $authChildNodeSub        = $_[0];    #Author from XML file
    my @XMLAuth = split(/\|/, $authChildNodeSub); #Array of XML author name
    my %XMLAuthorHash;
    my %lastNHits               = %{$_[1]}; #IndexNum of LastN_search pos result
    my %Fn_indexSub             = %{$_[2]}; #First Name Author Index
    my $name;                 #XML author name being checked
    #my $fName;                 #NOT USED???
    #my %XMLAuthorNameHash;     #NOT USED???
    my %PosHashSearch;        #Hash of FirstName at PosID
    my $PosID;                #Current pos last name IndexNum
    my $id;                   #IndexNum of index author currently being checked
    my $fn;                   #FirstName of index author currently being checked
    my $first_Initial;        #Initial of First Name being checked

    # Palces XML citation name into hash so we can search key
    foreach $name(@XMLAuth){
        $XMLAuthorHash{$name}=$name; 
    }

    # Places first names into hash for searching
    foreach $PosID(%lastNHits){     
        $PosHashSearch{$PosID}=$Fn_indexSub{$PosID};        
    }

    # Compares XML author to potential first names and first initial
    while (($id,$fn) = each (%PosHashSearch)){
        $fn             =~ s/\s+//g;    # Removes all whitespace  
        if (exists($XMLAuthorHash{$fn})){
            return ("found", $id);
        }   
        $first_Initial  = substr $fn, 0, 1;
        if (exists($XMLAuthorHash{$first_Initial})){
            #If result is pos returns "found" and IndexNum of pos result
            return ("found", $id);
        }
        else{}
    }


# DEBUG: The following is to print/test hashes
#    foreach (sort keys %PosHashSearch) {
#        print "$_ : $PosHashSearch{$_}\n";
#    }


    return ("null", "null");

}