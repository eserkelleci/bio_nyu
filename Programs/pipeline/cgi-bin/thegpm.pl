#!c:/perl/bin/perl.exe
##!/usr/bin/perl
##
## Version 2003.12.1
## Version 2004.03.01
## Version 2004.08.06
## Version 2004.10.15 - add call to get_root()
## Version 2004.10.29 - add proex var; the minimum protein expect, default to -1.0
## Version 2004.11.15 - add zip and gzip functionality for spectra input
## Version 2004.11.23 - added select versions of some input variable names
## Version 2004.11.24 - improved handling of uid numbers to make upgrades easier
## Version 2005.01.01 - added additional processing for multiple potential modification refinements
## Version 2005.08.21 - added support for multiline values
## Version 2006.05.01 - added support running X! Hunter searches
## Version 2006.12.12 - adapted to use methods
## Version 2007.01.02 - fixed problem caused by adaptation to methods
## Version 2007.01.06 - fixed another problem caused by adaptation to methods
## thegpm.pl
## Copyright (C) 2003 Ronald C Beavis, all rights reserved
## The Global Proteome Machine 
## This software is a component of the X! proteomics software
## development project
##
## Use of this software governed by the Artistic license,
## as reproduced at http://www.opensource.org/licenses/artistic-license.php
##

## thegpm.pl is the initial script called when a search is run. It creates a <bioml>
## file to be used as input to tandem, executes tandem, passing the input file
## as the only paramater, and forwards the browser to plist.pl with the result
## xml file as the only parameter.

##  parameters (CGI): 
##		all the parameters from the form
##	called by: thegpm_tandem.html or thegpm_tandem_a.html
##	required by: none
##	calls/links to: plist.pl (forward)

use strict;
use CGI qw(:all);
use CGI::Carp qw(fatalsToBrowser);
use File::Copy;

require "./defines.pl";  
require "pipeline_cgi_projexp.pl";
  
my $ip = $ENV{'REMOTE_ADDR'};
my $line="";
my %SETTINGS=(); open(IN,"../../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; } } close(IN);
my $version = "thegpm.pl, version 2010.02.04";

my $cgi = CGI->new();
my %method=();

my $uid_file = "./method/uid.txt"; 
my $gpm_id = get_gpm_number();

my $g_uid = 0;
GetUid();
$_ = PadUid($g_uid);      
my $GPM = $gpm_id . $_;
my $xml_path = "/archive/" . $gpm_id . $_ . ".xml";
my $test_path = get_root() . $xml_path;
while(-e $test_path || -e "$test_path.gz")	{
	GetUid();
	$_ = PadUid($g_uid);
	$xml_path = "/archive/" . $gpm_id . $_ . ".xml";
	$test_path = get_root() . $xml_path;
}
my $input_xml=$cgi->param("method_name");
##### all spaces and special characters replaced by _ in names : begin #####
$input_xml=~tr/ /\_/;
##### end #####	
$input_xml=$input_xml.".xml";

my $dir="ID/xtandem.pl/inactive";
my ($one, $two) = GetMethods($dir);
my @methods1 = @$one;
$dir="ID/xtandem.pl";
my ($three, $four) = GetMethods($dir);
my @methods2 = @$three;
my @methods = (@methods1,@methods2);
PrintHeader();

foreach my $val(@methods) { $method{$val}="1"; }
if($method{$input_xml}=~/\w/) 
{
	print "This name already exists<BR>";
	print "Please choose another name \n";
	my $return = 1;
}
else
{
	my $proex = -1.0;
	##
	## Create simple XML document for the search engine to read
	##
	## Add relative path information to the output path for the search engine
	##
	## Open the XML file to carry the input parameters to the search engine
	##
	open(OUTPUT,qq!>$input_xml!) || die print "cannot open file $input_xml<BR>Parameter transmission failed.<BR>\n"; 
	##
	## Write the XML file - in this case in bioml
	##
	print OUTPUT "<?xml version=\"1.0\" encoding=\"iso-8859-1\" ?>\n<bioml>\n";
	print OUTPUT "<note type=\"input\" label=\"spectrum, path\"></note>\n";
	if($cgi->param("output, title") == 0)	{
		print OUTPUT "<note type=\"input\" label=\"output, title\">";
		print OUTPUT "</note>\n";
	}
	print OUTPUT "<note type=\"input\" label=\"output, path\"></note>\n\n";
	##
	## Place each parameter into a <note> by 
	## placing the name into the "label" attribute
	## and the value into the body of the <note>
	##
	my $entry;
	my $value;
	my %p3_taxa;
	load_taxa(\%p3_taxa,"./method/p3.txt");
	my %hunter_taxa;
	load_taxa(\%hunter_taxa,"./method/hunter.txt");
	my $p3_ok = 1;
	my $hunter_ok = 1;
	my @main_taxon;

	foreach $entry ($cgi->param())	{
		$value = $cgi->param($entry);
		$value = cleanup($value);
		if($entry ne "submit" && $entry ne "lpdp" && not ($entry =~ /protein, taxon/))	{
			print OUTPUT "<note type=\"input\" label=\"$entry\">";
			my @val = $cgi->param($entry);
			my $u = 0;
			my %uk;
			while($u < scalar(@val))	{
				$uk{cleanup(@val[$u])} = 1;
				$u++;
			}
			$value = join ', ',keys(%uk);
			$value =~ s/\, $//;
			print OUTPUT $value;
			print OUTPUT "</note>\n";
		}
		if($entry eq "lpdp")	{
			print OUTPUT "<note type=\"input\" label=\"list path, default parameters\">";
			print OUTPUT "..$value";
			print OUTPUT "</note>\n";
		}
		if($entry eq "method")	{
			print OUTPUT "<note type=\"input\" label=\"list path, default parameters\">";
			$value =~ s/^\s+//;
			$value =~ s/\s+$//;
			print OUTPUT ".\\archive\\$value.xml";
			print OUTPUT "</note>\n";
		}
		if($entry =~ /protein, taxon\d*/)	{
			my @taxon = $cgi->param($entry);
			my $a;
			my %tax;
			foreach $a(@taxon)	{
				if(not $tax{$a})	{
					push(@main_taxon,$a);
					$tax{$a} = 1;
				}
			}
		}
		if($entry =~ /residue, modification mass/ and not($entry =~ /select/))	{
			print OUTPUT "<note type=\"input\" label=\"$entry\">";
			my @mods = $cgi->param($entry . " select");
			my $v;
			if($cgi->param("$entry") =~ /@/)	{
				print OUTPUT $cgi->param("$entry");
			}
			else	{
			if(scalar(@mods) > 0)	{
					$v = @mods[0];
					print OUTPUT "$v";
					my $a = 1;
					my $len = scalar(@mods);
					while($a < $len)	{
						$v = @mods[$a];
						print OUTPUT ",$v";
						$a++;
					}
				}
			}
			print OUTPUT "</note>\n";
		}
		if($entry =~ /refine, modification mass/ and not($entry =~ /select/))	{
			print OUTPUT "<note type=\"input\" label=\"$entry\">";
			my @mods = $cgi->param($entry . " select");
			my $v;
			if($cgi->param("$entry") =~ /@/)	{
				print OUTPUT $cgi->param("$entry");
			}
			else	{
			if(scalar(@mods) > 0)	{
					$v = @mods[0];
					print OUTPUT "$v";
					my $a = 1;
					my $len = scalar(@mods);
					while($a < $len)	{
						$v = @mods[$a];
						print OUTPUT ",$v";
						$a++;
					}
				}
			}
			print OUTPUT "</note>\n";
		}
		if($entry eq "residue, potential modification mass")	{
			print OUTPUT "<note type=\"input\" label=\"residue, potential modification mass\">";
			$entry = "residue, potential modification mass select";
			my @mods = $cgi->param($entry);
			my $v;
			if($cgi->param("residue, potential modification mass") =~ /@/)	{
				print OUTPUT $cgi->param("residue, potential modification mass");
			}
			else	{
			if(scalar(@mods) > 0)	{
					$v = @mods[0];
					print OUTPUT "$v";
					my $a = 1;
					my $len = scalar(@mods);
					while($a < $len)	{
						$v = @mods[$a];
						print OUTPUT ",$v";
						$a++;
					}
				}
			}
			print OUTPUT "</note>\n";
		}
		if($entry =~ /refine, potential modification mass/ and not($entry =~ /select/))	{
			print OUTPUT "<note type=\"input\" label=\"$entry\">";
			my @mods = $cgi->param($entry . " select");
			my $v;
			if($cgi->param("$entry") =~ /@/)	{
				print OUTPUT $cgi->param("$entry");
			}
			else	{
			if(scalar(@mods) > 0)	{
					$v = @mods[0];
					print OUTPUT "$v";
					my $a = 1;
					my $len = scalar(@mods);
					while($a < $len)	{
						$v = @mods[$a];
						print OUTPUT ",$v";
						$a++;
					}
				}
			}
			print OUTPUT "</note>\n";
		}

	}

	if($cgi->param("protein, cleavage site") =~ /\|/ or $cgi->param("protein, cleavage site select") =~ /\|/ )	{
		print OUTPUT "<note type=\"input\" label=\"protein, cleavage site\">";
		if($cgi->param("protein, cleavage site") =~ /\|/)	{
			print OUTPUT $cgi->param("protein, cleavage site");
		}
		else	{
			print OUTPUT $cgi->param("protein, cleavage site select");
		}
		print OUTPUT "</note>\n";
	}

	if(scalar(@main_taxon) > 0)	{
		print OUTPUT "<note type=\"input\" label=\"protein, taxon\">";
		my $v;
		if(scalar(@main_taxon) > 0)	{
			my $first = 0;
			foreach $v(@main_taxon)	{
				if($v =~ /\S/)	{
					$p3_ok = $p3_ok && $p3_taxa{$v};
					$hunter_ok = $hunter_ok && $hunter_taxa{$v};
					if($first == 0)	{
						print OUTPUT "$v";
						$first = 1;
					}
					else	{
						print OUTPUT ", $v";
					}
				}	
			}
		}
		print OUTPUT "</note>\n";
	}
	my ($gv) = $xml_path =~ /(GPM\d+)/;
	print OUTPUT "</bioml>\n";
	close(OUTPUT);
	####
	## Moving the method xml file onto isilon
	####
	copy($input_xml, "$SETTINGS{'TASKS'}/methods/ID/xtandem_cluster.pl");
	system(qq!Iacls "$SETTINGS{'TASKS'}/methods/ID/xtandem_cluster.pl/$input_xml" /e /g DEPCH:f!);
	move($input_xml, "$SETTINGS{'TASKS'}/methods/ID/xtandem.pl");
	system(qq!Iacls "$SETTINGS{'TASKS'}/methods/ID/xtandem.pl/$input_xml" /e /g DEPCH:f!);
	system(qq!del .\\$input_xml!);
	####
	## End of code
	####
	##
	## Start search engine with system command
	## Note: this redirects stdout to the started process and waits until it is done
	##
	my $return = 0;
	Redirect();	
	unlink($input_xml);
}
sub PrintHeader
{
	print <<End_of_header;
Content-type: text/html


	<HTML>
		<HEAD>
			<TITLE>Method Creation</TITLE>
			<meta http-equiv="Pragma" CONTENT="no-cache">
			<meta http-equiv="cache-control" content="no-cache">
	</HEAD>
	</HTML>
End_of_header
}

sub Redirect
{
	print <<End_of_header;


	<HTML>
		<HEAD>
			<meta http-equiv=\"refresh\" content=\"0; URL=http://10.193.36.219/pipeline-cgi/pipeline_cgi.pl?status=ViewMethods\">
	</HEAD>
	</HTML>
End_of_header
}

sub GetUid
{
	if(open(UID,"<$uid_file"))	{
		$g_uid = <UID>;
		close(UID);
	}
	$g_uid++;
	open(UID,">$uid_file");
	print UID $g_uid;
	close(UID);
	return;
}

sub PadUid
{
	my ($s) = @_;
	my @v = split //,$s;
	my $length = scalar(@v);
	my $a = 7;
	my @pad;
	while($a >= $length)	{
		push(@pad,'0');
		$a--;
	}
	my $out = join "",@pad;
	$out .= $s;
	return $out;
}

sub PrintPictures
{
	my ($_s) = @_;
	my $v = int(rand(100));
	$v = ($v % 2);
	$v++;
	my $line = "&nbsp;<img src=\"/pics/tornado_$v.gif\" border=\"0\" />&nbsp;";
	foreach $v(@$_s)	{
		if($v =~ /human/)	{
			$line .= "&nbsp;<img width=\"60\" height=\"48\" src=\"/pics/hs.gif\" border=\"0\" />&nbsp;";
		}
		elsif($v =~ /rat/)	{
			$line .= "&nbsp;<img width=\"60\" height=\"48\" src=\"/pics/rr.gif\" border=\"0\" />&nbsp;";
		}
		elsif($v =~ /mouse/)	{
			$line .= "&nbsp;<img width=\"60\" height=\"48\" src=\"/pics/mm.gif\" border=\"0\" />&nbsp;";
		}
		elsif($v =~ /yeast/)	{
			$line .= "&nbsp;<img width=\"60\" height=\"48\" src=\"/pics/sc.gif\" border=\"0\" />&nbsp;";
		}
		elsif($v =~ /chicken/)	{
			$line .= "&nbsp;<img width=\"60\" height=\"48\" src=\"/pics/gg.gif\" border=\"0\" />&nbsp;";
		}
		elsif($v =~ /dog/)	{
			$line .= "&nbsp;<img width=\"60\" height=\"48\" src=\"/pics/cf.gif\" border=\"0\" />&nbsp;";
		}
		elsif($v =~ /cow/)	{
			$line .= "&nbsp;<img width=\"60\" height=\"48\" src=\"/pics/bt.gif\" border=\"0\" />&nbsp;";
		}
		elsif($v =~ /cat/)	{
			$line .= "&nbsp;<img width=\"60\" height=\"48\" src=\"/pics/fc.gif\" border=\"0\" />&nbsp;";
		}
	}
	if(length($line))	{
		print $line;
	}
	print "<br>\n";
}

sub load_taxa
{
	my ($hash,$path) = @_;
	open(IN,"<$path") or return;
	while(<IN>)	{
		chomp($_);
		s/^\s+//;
		s/\s+$//;
		$$hash{$_} = 1;
	}
	close(IN);
}

sub cleanup
{
	my ($_v) = @_;
	$_v =~ s/\s+/ /gm;
	$_v =~ s/&/&amp;/g;
	$_v =~ s/\</&lt;/g;
	$_v =~ s/\>/&gt;/g;
	$_v =~ s/[\"\']/&quot;/g;
	$_v =~ s/[^\/\w\s\{\}\[\]\*\.\(\)\-\`\!\+\=\&\;\,\:\@\~\#\$\%\^\?\|\\]/-/g;
	return $_v;	
}
