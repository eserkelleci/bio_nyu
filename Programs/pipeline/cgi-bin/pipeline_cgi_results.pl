#!c:/perl/bin/perl.exe
sub numerically { $a <=> $b; }
sub numericallydesc { $b <=> $a; }

use CGI;
$query = new CGI;
%SETTINGS=(); open(IN,"../../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);
@STEPS_LIST=();
@DATA_FILES=();
$count=0;
sub GetDataAnalysisSteps
{
	my $date=$_[0];
	my $analysisfile=$_[1];
	my $res_dir=$_[2]; 
	open(IN,qq!$SETTINGS{'RESULT'}/$res_dir$date/methods/$analysisfile.xml!) || die "Could not open $analysisfile.xml file\n";
	while($line=<IN>)
	{
		if($line =~/\<step type\=\"(.*)\" program\=\"(.*)\" method\=\'(.*)\'\/>/)
		{
			$STEPS_LIST[$count++]="$1 ($2, $3)";
		}
	}
	return @STEPS_LIST;
}
$count=0;
sub GetDataAnalysisInputFiles
{
	my $date=$_[0];
	my $analysisfile=$_[1];
	my $step=$_[2];
	my $num=$_[3]; 
	my $res_dir=$_[4]; 
	
	open(IN,qq!$SETTINGS{'RESULT'}/$res_dir$date/methods/$analysisfile.xml!) || die "Could not open $analysisfile.xml file\n";
	while($line=<IN>)
	{
		if($line =~/\<experiment file=".*\/(.*)\.xml"\/\>/)
		{
			$experimentfile=$1; 
		}
	}
	open(IN,qq!$SETTINGS{'RESULT'}/$res_dir$date/methods/$experimentfile\_step$num.xml!) || die "Could not open $experimentfile.xml file\n"; 
	while($line=<IN>)
	{ 
		if($line =~/<file path=\".*\/(.*)\" \/>/)
		{
			$DATA_FILES[$count++]="$1"; 
		}
	}
	return @DATA_FILES;
}
1;


