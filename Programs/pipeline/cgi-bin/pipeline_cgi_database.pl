#!c:/perl/bin/perl.exe

print "Content-type: text/html\n\n";
use CGI;
$query = new CGI;

my $status=$query->param("status");
my $message="";
%SETTINGS=(); open(IN,"../../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; }}
my $tasks=$SETTINGS{'TASKS'};
$tasks=~s/\//\\/g; 

print qq!<b><a href="pipeline_cgi.pl?status=ViewProject&project_id=-1">Home</a></b>!;
print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b><a href="pipeline_cgi.pl?status=ViewMethods">Methods</a></b>!;
print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b><a href="pipeline_cgi.pl?status=ViewQueue">Queue</a></b>!;
print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b><a href="pipeline_cgi.pl?status=ViewTools">Tools</a></b>!;
print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b><a href="pipeline_cgi_database.pl?status=CreateDatabase">Database</a></b><br><br>!;
if ($status=~/^CreateDatabase$/)   
{
	print qq!
		<FORM ACTION="pipeline_cgi_database.pl" METHOD="post" ENCTYPE="multipart/form-data">
		<INPUT TYPE="hidden" NAME="status" VALUE="CreateDb">
		<b>Database Name:</b> <INPUT TYPE="text" NAME="database_name"><br><p>
		<b>FASTA file1:</b> <INPUT TYPE="file" NAME="fasta1"><br>
		<b>FASTA file2:</b> <INPUT TYPE="file" NAME="fasta2"><br>
		<b>FASTA file3:</b> <INPUT TYPE="file" NAME="fasta3"><br><p>
		<select name="organism">
		<option value="yeast">Yeast</option>
		<option value="ecoli">Ecoli</option>
		<option value="mouse">Mouse</option>
		<option value="human">Human</option>
		<option value=" "> </option>
		</select><p><br>
		<INPUT TYPE="submit" NAME="Submit" VALUE="Create">
		</FORM><p>
		<br><br>
	!;
}
if($status=~/^CreateDb$/)
{
	my $ok=1; 
	my $organism = $query->param("organism");
	my $upload_filehandle = $query->upload("fasta1");
	if(!$upload_filehandle ) { print qq!<font color="red"><b>Database file is missing.</b></font>!; exit(-1); }
	my $fasta_name = $query->param("database_name");
	if($fasta_name!~/\w/) { print qq!<font color="red"><b>Database name is missing.</b></font>!; exit(-1); }
	$fasta_name=~tr/ /\_/;
	my $database_name = $fasta_name;
	$database_name=~tr/ /\_/;
	##### check for existing file names: begin ######
	if (opendir(dir,"$SETTINGS{'TASKS'}/Databases_Custom"))
	{
		my @allfiles=readdir dir;
		closedir dir;
		foreach my $files (@allfiles)
		{
			if (($files=~/\.fasta$/i))
			{
				$files=~s/\.fasta$//;
				if(($files eq $fasta_name))
				{
					print qq!<font color="red"><b>Error: Database name already exists\!</b></font><br>!;
					print qq!<font color="red"><b>Please choose another name.</b></font>!;
					exit(-1);
				}
			}
		}
	}
	##### check for existing file names: end  ######
	my $dbname=$database_name;
	$original_database="$tasks\\Databases_Custom\\".$database_name."\.original";
	$database_log="$tasks\\Databases_Custom\\".$database_name."\.log";
	$database_log_="$SETTINGS{'TASKS'}\/Databases_Custom\/".$database_name."\.log";
	$database_log__=$database_name."\.log";
	$database_name_="$SETTINGS{'TASKS'}\/Databases_Custom\/".$database_name."\.fasta";
	$database_name="$tasks\\Databases_Custom\\".$database_name."\.fasta";
	
	##### upload fasta file on d:/database_custom #####
	if (open UPLOADFILE, ">$original_database")
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
	
	$upload_filehandle = $query->upload("fasta2");
	if (open UPLOADFILE, ">>$original_database")
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
	
	$upload_filehandle = $query->upload("fasta3");
	if (open UPLOADFILE, ">>$original_database")
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
	
	######## check and clean original database file, write into a fasta file and write log file : begins #######
	if (open (IN,"$original_database"))
	{
		if (open (LOG,">$database_log"))
		{
			my $name="";
			my $description="";
			my $sequence="";
			my $line="";
			my %names=();
			my %sequences=();
			my %descriptions=();
			my %names_=();
			my %names_count=();
			while ($line=<IN>)
			{
				chomp($line);
				if ($line=~/^>\s*(\S+)\s?(.*)$/)
				{
					my $name_=$1;
					my $description_=$2;
					$sequence=~s/\*+$//;
					if ($name=~/\w/ and $sequence=~/\w/)
					{
						my $this_error=0;
						my $sequence_=$sequence;
						my %characters=();
						while ($sequence_=~s/^(.)//)
						{
							$characters{$1}++;
						}
						foreach my $char (keys %characters)
						{
							if ($char!~/([ABCDEFGHIKLMNPQRSTUVWXYZ\s]+)/)
							{
								print LOG qq!Strange character: $characters{$char} $char\t$name\n!;
								$error=1;
								$this_error=1;
							}
						}
						if($this_error==0)
						{
							$names{$name}++;
							$sequence=~s/\s//g;
							$sequences{$name}.="#$sequence#";
							$descriptions{$name}.="#$description#";
							$names_{$sequence}.="#$name#";
							$names_count{$sequence}++;
						}
					}
					else
					{
						if ($name=~/\w/)
						{
							if ($sequence!~/\w/)
							{
								print LOG qq!Sequence missing\t$name\n!;
							}
						}
					}
					$name=$name_;
					$description=$description_;
					$sequence="";
				}
				else
				{
					$sequence.="\U$line";
				}
			}
			$sequence=~s/\*+$//;
			if ($name=~/\w/ and $sequence=~/\w/)
			{
				my $this_error=0;
				my $sequence_=$sequence;
				my %characters=();
				while ($sequence_=~s/^(.)//)
				{
					$characters{$1}++;
				}
				foreach my $char (keys %characters)
				{
					if ($char!~/([ABCDEFGHIKLMNPQRSTUVWXYZ\s]+)/)
					{
						print LOG qq!Strange character: $characters{$char} $char\t$name\n!;
						$error=1;
						$this_error=1;
					}
				}
				if($this_error==0)
				{
					$names{$name}++;
					$sequence=~s/\s//g;
					$sequences{$name}.="#$sequence#";
					$descriptions{$name}.="#$description#";
					$names_{$sequence}.="#$name#";
					$names_count{$sequence}++;
				}
			}
			else
			{
				if ($name=~/\w/)
				{
					if ($sequence!~/\w/)
					{
						print LOG qq!Sequence missing\t$name\n!;
					}
				}
			}
					
			# foreach my $name (keys %names)
			# {
				# if ($names{$name}>1)
				# {
					# my $temp=$sequences{$name};
					# my $same="Seqences identical";
					# my $previous="";
					# while($temp=~s/^#([^#]+)#//)
					# {
						# my $seq=$1;
						# if ($previous=~/\w/)
						# {
							# if ($previous!~/^$seq$/) { $same="Seqences different"; }
						# }
						# $previous=$seq;
					# }
					# print LOG qq!ID repeated $names{$name} times\t$name\t$same\n!;
				# }
			# }
			# my $count=0;
			# my $count_=0;
			# foreach my $seq (keys %names_)
			# {
				# my $temp=$names_{$seq};
				# if ($names_count{$seq}>1)
				# {
					# print LOG qq!Sequence repeated $names_count{$seq} times!;
					# while($temp=~s/^#([^#]+)#//)
					# {
						# my $name=$1;
						# print LOG qq!\t$name!;
					# }
					# print LOG qq!\n!;
				# }
			# }
			close(LOG);
			if( !-s "$database_log") 
			{
				my $count=0;
				my $count_=0; 
				system(qq!del "$database_log"!);
				open (OUT,">$database_name");
				foreach my $seq (keys %names_)
				{
					my $temp=$names_{$seq}; 
					if($temp=~/^#([^#]+)#/)
					{
						my $name=$1;
						print OUT qq!>$name !; 
						my $temp_=$descriptions{$name};
						$temp_=~s/^#([^#]+)#.*$/$1/; 
						if ($description=~/\w/) { print OUT qq!$temp_!;  }
						my $temp_=$sequences{$name};
						$temp_=~s/^#([^#]+)#.*$/$1/;
						print OUT qq!\n$temp_\n!;  
						$count_++;
						$count+=$names_count{$seq};
					}
				}
				##### create taxonomy backup #####
				$new_taxonomy="$tasks\\tandem\\taxonomy.xml";
				$old_taxonomy="$tasks\\tandem\\taxonomy.xml\-".GetDateTime_();
				rename("$new_taxonomy","$old_taxonomy");
				##### update taxonomy #####
				open(IN,$old_taxonomy);
				open(OUT,">$new_taxonomy");
				while($line=<IN>)
				{
					if($line!~/<\/bioml>/) { print OUT "$line"; }	
				}
				close(IN);
				close(OUT);
				open(OUT,">>$new_taxonomy");
				print OUT qq!\n!;
				if($organism=~/yeast/)
				{
					print OUT qq!<taxon label="$dbname">\n!;
					print OUT  qq!<file format="peptide" URL="$database_name_" />\n!;
					print OUT  qq!<file format="spectrum" URL="$SETTINGS{'TASKS'}\/Databases\/lib\/crap_cmp_20.hlf" \/>\n!;
					print OUT  qq!<file format="mods" URL="$SETTINGS{'TASKS'}\/Databases\/mods\/crap_mod.xml" \/>\n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases\/fasta\/crap.fasta.pro"\/>\n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases_Custom\/crap_enzymes.fasta"\/>\n!;
					print OUT  qq!<file format="spectrum" URL="$SETTINGS{'TASKS'}\/Databases\/lib\/yeast_cmp_20.hlf" \/> \n!;
					print OUT  qq!<file format="spectrum" URL="$SETTINGS{'TASKS'}\/Databases\/lib\/virus\/Saccharomyces_cerevisiae_virus_L_A__L1__cmp_20.hlf"\/> \n!;
					print OUT  qq!<file format="spectrum" URL="$SETTINGS{'TASKS'}\/Databases\/lib\/virus\/Saccharomyces_cerevisiae_virus_L_BC__La__cmp_20.hlf"\/> \n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases\/fasta\/yeast_e.fasta.pro" \/> \n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases\/fasta\/virus\/Saccharomyces_cerevisiae_virus_L_A_L1.fasta.pro"\/> \n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases\/fasta\/virus\/Saccharomyces_cerevisiae_virus_L_BC_La.fasta.pro"\/> \n!;
					print OUT  qq!<file format="mods" URL="$SETTINGS{'TASKS'}\/Databases\/mods\/yeast_mod.xml" \/>\n !;
					print OUT  qq!<file format="saps" URL="$SETTINGS{'TASKS'}\/Databases\/saps\/yeast_saps.xml" \/>\n!;
					print OUT  qq!<\/taxon>\n!;
				}
				elsif($organism=~/ecoli/)
				{
					print OUT  qq!<taxon label="$dbname">\n!;
					print OUT  qq!<file format="peptide" URL="$database_name_" />\n!;
					print OUT  qq!<file format="spectrum" URL="$SETTINGS{'TASKS'}\/Databases\/lib\/crap_cmp_20.hlf" \/>\n!;
					print OUT  qq!<file format="mods" URL="$SETTINGS{'TASKS'}\/Databases\/mods\/crap_mod.xml" \/>\n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases\/fasta\/crap.fasta.pro"\/>\n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases_Custom\/crap_enzymes.fasta"\/>\n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases\/fasta\/bacteria\/Escherichia_coli_BL21_DE3.fasta.pro"\/>\n!;
					print OUT  qq!<\/taxon>\n!;
				}
				elsif($organism=~/mouse/)
				{
					print OUT  qq!<taxon label="$dbname">\n!;
					print OUT  qq!<file format="peptide" URL="$database_name_" />\n!;
					print OUT  qq!<file format="spectrum" URL="$SETTINGS{'TASKS'}\/Databases\/lib\/crap_cmp_20.hlf" \/>\n!;
					print OUT  qq!<file format="mods" URL="$SETTINGS{'TASKS'}\/Databases\/mods\/crap_mod.xml" \/>\n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases\/fasta\/crap.fasta.pro"\/>\n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases_Custom\/crap_enzymes.fasta"\/>\n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}/Databases/fasta/mouse/uniprot_mouse_20140214.fasta" />\n!;
					print OUT  qq!<file format="mods" URL="$SETTINGS{'TASKS'}/Databases/mods/mouse_mod.xml" />\n!;
					print OUT  qq!<file format="saps" URL="$SETTINGS{'TASKS'}/Databases/saps/mouse_saps.xml" />\n!;
					print OUT  qq!<\/taxon>\n!;
				}
				elsif($organism=~/human/)
				{
					print OUT  qq!<taxon label="$dbname">\n!;
					print OUT  qq!<file format="peptide" URL="$database_name_" />\n!;
					print OUT  qq!<file format="spectrum" URL="$SETTINGS{'TASKS'}\/Databases\/lib\/crap_cmp_20.hlf" \/>\n!;
					print OUT  qq!<file format="mods" URL="$SETTINGS{'TASKS'}\/Databases\/mods\/crap_mod.xml" \/>\n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases\/fasta\/crap.fasta.pro"\/>\n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases_Custom\/crap_enzymes.fasta"\/>\n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}/Databases_Custom/uniprot_human_20140214.fasta" />\n!;
					print OUT  qq!<file format="mods" URL="$SETTINGS{'TASKS'}/Databases/mods/human_mod.xml" />\n!;
					print OUT  qq!<file format="saps" URL="$SETTINGS{'TASKS'}/Databases/saps/human_saps.xml" />\n!;
					print OUT  qq!<\/taxon>\n!;
				}
				elsif($organism=~/ /)
				{
					print OUT  qq!<taxon label="$dbname">\n!;
					print OUT  qq!<file format="peptide" URL="$database_name_" />\n!;
					print OUT  qq!<file format="spectrum" URL="$SETTINGS{'TASKS'}\/Databases\/lib\/crap_cmp_20.hlf" \/>\n!;
					print OUT  qq!<file format="mods" URL="$SETTINGS{'TASKS'}\/Databases\/mods\/crap_mod.xml" \/>\n!;
					print OUT  qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases\/fasta\/crap.fasta.pro"\/>\n!;
					print OUT qq!<file format="peptide" URL="$SETTINGS{'TASKS'}\/Databases_Custom\/crap_enzymes.fasta"\/>\n!;
					print OUT  qq!<\/taxon>\n!;
				}
				print OUT qq!<\/bioml>!;
				close(OUT);
				
				##### update pro_species.js #####
				open(OUT,">>$tasks\\tandem\\pro_species.js");
				print OUT qq!\n!;
				print OUT qq!document.writeln("<option value=\\"$dbname\\">$dbname<\/option>")\;!;
				close(OUT);
				
				print qq!<font color="red"><p><b>$dbname database created successfully\!</b></p></font>!;
			} 
			else
			{
				print qq!<font color="red"><p><b>Database Error: Could not create database due to erroneous fasta file</b></p></font>!;
				print qq!<font color="red"><p><b>Check log file	</b></font> 	 <a href="/log/$database_log__">Log file</a></p>!;
			}
		}
		close(OUT);
		close(IN);
	}
	######## check and clean original database file, write into a fasta file and write log file : ends #######
}

sub GetDateTime_
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
	$date="$year-$mon-$mday-$hour-$min-$sec";
	
	return $date;
}
