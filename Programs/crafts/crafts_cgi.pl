#!c:/perl/bin/perl.exe
##!c:/perl64/bin/perl.exe

use Scalar::Util qw(looks_like_number);
use CGI;
$query = new CGI;
print "Content-type: text/html\n\n";
%SETTINGS=(); open(IN,"settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);

my $status=$query->param("status");

if ($status!~/\w/)
{
	print qq!
		<FORM ACTION="crafts_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
		<INPUT TYPE="hidden" NAME="status" VALUE="CRAFTS">
		<b>Data:</b> <INPUT TYPE="file" NAME="data_file"><br>
		<INPUT TYPE="submit" NAME="Submit" VALUE="CRAFTS">
		</FORM><p>
		<br><br>
	!;
}
else
{	
	if ($status=~/^CRAFTS$/)
	{
		$cutoff=0.2;
		$id = GetDateTime();
		$id .= "-" . int(123456789*rand());
		mkdir("$SETTINGS{'RESULTS'}/$id");
		my $ok=1;
		my $upload_filehandle = $query->upload("data_file");
		if (open UPLOADFILE, ">$SETTINGS{'RESULTS'}/$id/data.txt")
		{
			while ( $line=<$upload_filehandle> ) 
			{
				chomp($line);
				$line=~s/\r$//;
				$line=~s/\r([^\n])/\n$1/g;
				print UPLOADFILE "$line\n";
			}
			close UPLOADFILE;
		} else { $ok=0; }
		if ($ok==1)
		{
			if (open OUT, ">$SETTINGS{'RESULTS'}/$id/Run_CRAFTS_.m")
			{
				print OUT qq!close all; clear all; clc;
cd $SETTINGS{'RESULTS'}/$id
print(\"$id\")
fid = fopen(\'data.txt\');
data = read_text_file(fid);
fclose(fid);
[ratio_H1_log4, ratio_L1_log4, namesH1, namesL1 ] = Run_CRAFTS( light_int, heavy_int, light_simple, heavy_simple, light_ion, heavy_ion, $cutoff, \'$id\')
!;
				close(OUT);
				system(qq!"$SETTINGS{'MATLAB'}" -m "$SETTINGS{'RESULTS'}/$id/Run_CRAFTS_.m" >> "matlab.log" 2>&1!);
			}
		}
	}
}

sub GetDateTime
{
	my $sec="";
	my $min="";
	my $hour="";
	my $mday="";
	my $mon="";
	my $year="";

	($sec,$min,$hour,$mday,$mon,$year) = localtime();

	if ($sec<10) { $sec="0$sec"; }
	if ($min<10) { $min="0$min"; }
	if ($hour<10) { $hour="0$hour"; }
	if ($mday<10) { $mday="0$mday"; }
	$mon++;
	if ($mon<10) { $mon="0$mon"; }
	$year+=1900;
	$date="$year$mon$mday-$hour$min$sec";
	
	return $date;
}