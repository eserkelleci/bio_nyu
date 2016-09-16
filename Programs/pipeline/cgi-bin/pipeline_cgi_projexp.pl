#!c:/perl/bin/perl.exe
sub numerically { $a <=> $b; }
sub numericallydesc { $b <=> $a; }

use CGI;
use File::Copy;
use File::Path;
use Archive::Tar;
$query = new CGI;
my $ip = $ENV{'REMOTE_ADDR'};
%SETTINGS=(); open(IN,"../../settings.txt"); while($line=<IN>) { chomp($line); if ($line=~/^([^\=]+)\=([^\=]+)$/) { $SETTINGS{$1}=$2; }}
%PROJECT_NAME=();
%PROJECT_PARENT=();
%PROJECT_PATH=();
%PROJECT_OFFSPRING=();
%PROJECT_ALL_OFFSPRING=();
%EXPERIMENT_NAME=();
%EXPERIMENT_PROJECT=();
%EXPERIMENT_FILES=();
%EXPERIMENT_FILES_COUNT=();
%EXPERIMENT_DEFINITIONS=();
%METHODS=();
%METHODS_COUNT=();
%DATA_ANALYSIS_LIST=();
%PROJECT_ID=();
@allmethods=();

sub GetProjects
{
	my $project_id_=$_[0];
	my $project_parent_id_=$_[1];
	my $project_maxid=0;
	my $project_id=0;
	my $project_parent_id=0;
	my $project_name="";
	%PROJECT_NAME=();
	%PROJECT_PARENT=();
	%PROJECT_PATH=();
	%PROJECT_OFFSPRING=();
	%PROJECT_ALL_OFFSPRING=();
	%PROJECT_ID=();
	my %deleted=();
	if (open(infile,"$SETTINGS{'DATA'}/projects_deleted.dat"))
	{
		while($line=<infile>)
		{
			chomp($line);
			if ($line=~/^>([0-9]+)$/) 
			{ 
				$deleted{$1}=1;
			}	
		}
		close(infile);
	}
	if (open(infile,qq!$SETTINGS{'DATA'}/projects.dat!))
	{   
		while($line=<infile>)
		{   
			chomp($line);
			if ($line=~/^>([^#]*)#([^#]*)#([^#]*)$/) 
			{ 
				$project_id=$1;
				$project_parent_id=$2;
				$project_name=$3;
				if ($project_maxid<$project_id) { $project_maxid=$project_id; }
				if ($deleted{$project_id}!~/\w/)
				{	
					$PROJECT_NAME{$project_id}=$project_name; 
					$PROJECT_ID{$project_name}=$project_id;
					$PROJECT_PARENT{$project_id}=$project_parent_id; 
				}
			}	
		}
		close(infile);
	} 
	$PROJECT_PATH{-1}="/";
	foreach $project_id_ (keys %PROJECT_NAME)
	{	
		$PROJECT_PATH{$project_id_}="$PROJECT_NAME{$project_id_}";
		$project_parent_id=$PROJECT_PARENT{$project_id_};
		$PROJECT_OFFSPRING{$project_parent_id}.="#$project_id_#";
		$PROJECT_ALL_OFFSPRING{"-1"}.="#$project_id_#";
		while ($project_parent_id!=-1 and $project_parent_id=~/\w/)
		{
			$PROJECT_ALL_OFFSPRING{$project_parent_id}.="#$project_id_#";
			$PROJECT_PATH{$project_id_}="$PROJECT_NAME{$project_parent_id}/$PROJECT_PATH{$project_id_}";
			$project_parent_id=$PROJECT_PARENT{$project_parent_id};
		}
		$PROJECT_PATH{$project_id_}="/$PROJECT_PATH{$project_id_}";
	}          
	return $project_maxid;
}

sub GetExperimentFiles
{
	my $project_id=$_[0];
	my $dir=$_[1];
	
	$EXPERIMENT_FILES_COUNT{$project_id}=0;	
	$EXPERIMENT_FILES{$project_id}="";
	$EXPERIMENT_DEFINITIONS{$project_id}="";
	
	@allfiles=();
	system(qq!dir "$dir" > psftp_temp.$ip.log !); 
	if (open(IN,"psftp_temp.$ip.log"))
	{
		while($line=<IN>)
		{
			if ($line=~/(\S+\.xml)\s*$/i) { @allfiles=(@allfiles,$1); }
			if ($line=~/(\S+\.raw)\s*$/i) { @allfiles=(@allfiles,$1); }
			if ($line=~/(\S+\.mgf)\s*$/i) { @allfiles=(@allfiles,$1); }
			if ($line=~/(\S+\.mzXML)\s*$/i) { @allfiles=(@allfiles,$1); }
		}
		close(IN);
	}
	system(qq!del psftp_temp.$ip.log!);
	
	if (@allfiles>0)
	{   
		foreach $filename (@allfiles)
		{
			if ($filename=~/\.raw$/i or $filename=~/\.mgf$/i or $filename=~/\.mzXML$/i)
			{
				$EXPERIMENT_FILES{$project_id}.="#$filename#";
				$EXPERIMENT_FILES_COUNT{$project_id}++;
			}
			if ($filename=~/\.xml$/i)
			{
				$EXPERIMENT_DEFINITIONS{$project_id}.="#$filename#";
			}
		}
	}
	return $project_id;
}

sub AddProject
{
	my $project_parent_id=$_[0];
	my $project_name=$_[1];

	my $error=0;
	my $project_id=GetProjects(-1,-1)+1;
	if (open(outfile,">>$SETTINGS{'DATA'}/projects.dat"))
	{
		system(qq!dir "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}" > psftp_temp.$ip.log !);
		if (open(IN,"psftp.$ip.log"))
		{
			while($line=<IN>)
			{
				if ($line=~/^d.*$project_name$/)
				{
					if ($line!~/^drwxrw[sx].*$project_name$/)
					{
						print qq!<font color="#FF0000"><b>Please change permissions on the $SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name directory to allow group to read, write and execute. In FileZilla you can right-click on the directory and select "File permissions".</b></font><p>\n!;
						$project_id=$project_parent_id;
						$error=1;
					}
				}
			}
			close(IN);
		}
		system(qq!del psftp.$ip.log!);
		if ($error==0)
		{
			mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name");
			system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name" /e /g DEPCH:f!);
			mkdir("$SETTINGS{'RESULT'}/$PROJECT_PATH{$project_parent_id}/$project_name");
			system(qq!Iacls "$SETTINGS{'RESULT'}/$PROJECT_PATH{$project_parent_id}/$project_name" /e /g DEPCH:f!);
						
			mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/todo");
			# mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/todo/0");
			# mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/todo/1");
			# mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/todo/2");
			mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/running");
			mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/running/0");
			mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/running/1");
			mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/running/2");
			mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/done");
			# mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/done/0");
			# mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/done/1");
			# mkdir("$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/done/2");
			system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/todo" /e /g DEPCH:f!);
			# system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/todo/0" /e /g DEPCH:f!);
			# system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/todo/1" /e /g DEPCH:f!);
			# system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/todo/2" /e /g DEPCH:f!);
			system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/running" /e /g DEPCH:f!);
			system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/running/0" /e /g DEPCH:f!);
			system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/running/1" /e /g DEPCH:f!);
			system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/running/2" /e /g DEPCH:f!);
			system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/done" /e /g DEPCH:f!);
			# system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/done/0" /e /g DEPCH:f!);
			# system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/done/1" /e /g DEPCH:f!);
			# system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_parent_id}/$project_name/done/2" /e /g DEPCH:f!);
			
			print outfile ">$project_id#$project_parent_id#$project_name\n";
		}
		close(outfile);
	}
	return $project_id;
}

sub DeleteProject
{
	my $project_id=$_[0];

	if (open(outfile,">>$SETTINGS{'DATA'}/projects_deleted.dat"))
	{
		print outfile ">$project_id\n";
		close(outfile);
	}
	return $project_id;
}
sub ArchiveProject
{
	my $project_id=$_[0];
	my $tar = Archive::Tar->new;
	use File::Find; 
	my $project_path = $PROJECT_PATH{$project_id};
	my @inventory = (); 
	find (sub { push @inventory, $File::Find::name }, "$SETTINGS{'DATA'}$project_path/"); 
	$tar->add_files(@inventory);
	$tar->write("$SETTINGS{'DATA'}$project_path.tgz",COMPRESS_GZIP); 
	
	@inventory = (); 
	find (sub { push @inventory, $File::Find::name }, "$SETTINGS{'RESULT'}$project_path/"); 
	$tar->add_files(@inventory); 
	$tar->write("$SETTINGS{'RESULT'}$project_path.tgz",COMPRESS_GZIP); 
	
	$dir="$SETTINGS{'RESULT'}$project_path";
	rmtree($dir);
	$dir="";
	$dir="$SETTINGS{'DATA'}$project_path";
	rmtree($dir);
	
	return $project_id;
}
# sub AddExperimentDefinition
# {
	# my $project_id=$_[0];
	# my $name__=$_[1]; 
	# my $group_samples=$_[2];
	# my $sample_files=$_[3];
	# my $exptime= GetDateTime_();
	# $name = $name__.$exptime;
	# ##if (open(OUT,">$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/$EXPERIMENT_NAME{$experiment_id}/$name-experiment.xml")) #####
	# if (open(OUT,">$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/$name-experiment.xml")) #####
	# {
		# print OUT qq!<experiment>\n!; 
		# foreach my $group (sort numerically keys %$group_samples)
		# {
			# print OUT qq!\t<group id_="$group">\n!;
			# for(my $sample=1;$sample<=$EXPERIMENT_FILES_COUNT{$project_id};$sample++)
			# {
				# if (${$group_samples}{$group}=~/#$sample#/)
				# {				
					# print OUT qq!\t\t<sample id_="$sample">\n!;
					# $temp=$EXPERIMENT_FILES{$project_id};
					# for(my $file=0;$file<$EXPERIMENT_FILES_COUNT{$project_id};$file++)
					# {
						# if ($temp=~s/^#([^#]+)#//)
						# {
							# my $name_=$1;
							# if (${$sample_files}{$sample}=~/#$file#/)
							# {
								# print OUT qq!\t\t\t<file path="$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/$name_"/>\n!;
								# ####print OUT qq!\t\t\t<file path="$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/$EXPERIMENT_NAME{$experiment_id}/$name_">\n!;
							# }
						# }
					# }
					# print OUT qq!\t\t</sample>\n!;
				# }
			# }
			# print OUT qq!\t</group>\n!;
		# }
		# print OUT qq!</experiment>\n!;
		# close(OUT);
	# }
	# system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/$name-experiment.xml" /e /g DEPCH:f!);
# }

sub AddExperimentDefinition
{
	my $project_id=$_[0];
	my $name__=$_[1]; 
	my $sample_files=$_[2];
	$name = $name__;
	my $group=1;
	my $sample=1;
	if (open(OUT,">$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/$name-experiment.xml")) #####
	{
		print OUT qq!<experiment>\n!; 
		print OUT qq!\t<group id_="$group">\n!;
		foreach my $file(keys %$sample_files)
		{
			print OUT qq!\t\t<sample id_="$sample">\n!;
			print OUT qq!\t\t\t<file path="$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/$file"/>\n!;
			print OUT qq!\t\t</sample>\n!;
			$sample++;
		}
		print OUT qq!\t</group>\n!;
		print OUT qq!</experiment>\n!;
		close(OUT);
	}
	system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/$name-experiment.xml" /e /g DEPCH:f!);
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
	$date="$year-$mon-$mday $hour:$min:$sec";
	
	return $date;
}
sub GetMethods
{
	my $dir=$_[0];	
	@allmethods=();
	$method_count=0;
	system(qq!dir "$SETTINGS{'TASKS'}/methods/$dir" > psftp_temp.$ip.log !);
	if (open(IN,"psftp_temp.$ip.log"))
	{
		while($line=<IN>)
		{
			if ($line=~/(\S+\.xml)\s*$/i) { @allmethods=(@allmethods,$1); }
		}
		close(IN);
	}
	system(qq!del psftp_temp.$ip.log!);
	my @methods = sort{lc $a cmp lc $b}@allmethods;
	if (@methods>0)
	{   
		foreach $filename (@methods)
		{
			if ($filename=~/\.xml$/i)
			{
				$method_count++;
			}
		}
	}
	return (\@methods,$method_count);
}

sub AddAnalysisDefinition
{
	my $project_id=$_[0];
	my $name=$_[1];
	my $steps=$_[2];
	my $count=$_[3];
	my $methods=$_[4];
	my $name_project=$_[5];
	my $deletes=$_[6];
	my @process = @$steps;
	my @method = @$methods;
	my @delete = @$deletes;
	my $name_ = $name;
	$name_ =~s/[\-_]experiment.xml$//i;	 
	$projectpath=$PROJECT_PATH{$project_id};
	$projectpath=~s/\///;  
	$projectpath=~s/\//\-/g;
	if (open(OUT,">$SETTINGS{'TASKS'}/todo/$name_project\_\_$name_-analysis.xml")) 
	{
		open(IN,qq!$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/$name!);
		while($line=<IN>)
		{
			if ($line=~/\<file path.*\.([A-Za-z]+)"/) { $file = $1; }
		}
		close(IN);
		print OUT qq!<analysis>\n!;
		print OUT qq!\t<experiment file="$SETTINGS{'DATA'}$PROJECT_PATH{$project_id}/$name"/>\n!;
		print OUT qq!\t<result dir="$SETTINGS{'RESULT'}$PROJECT_PATH{$project_id}"/>\n!;
		for(my $j=0; $j<$count; $j++)
		{
			my ($type,$prog) = split(': ', $process[$j]);
			print OUT qq!\t<step type="$type" program="$prog" method='$method[$j]'/>\n! ; 
		}
		for(my $j=0; $j<$count; $j++)
		{
			if($delete[$j]==1)
			{
				my $j_=$j+1;
				print OUT qq!\t<step type="Cleanup" program="del_exp.pl" method="step$j_"/>\n! ;
			}
		}
		print OUT qq!</analysis>\n!;
		close(OUT);
	}
	system(qq!Iacls "$SETTINGS{'TASKS'}/todo/$name_project\_\_$name_-analysis.xml" /e /g DEPCH:f!);
	# copy("$SETTINGS{'TASKS'}/todo/$name_project\_\_$name_-analysis.xml", "$SETTINGS{'DATA'}$PROJECT_PATH{$project_id}/todo/$SETTINGS{'DEMON'}/$name_project\_\_$name_-analysis.xml");
	# system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/todo/$SETTINGS{'DEMON'}/$name_project\_\_$name_-analysis.xml" /e /g DEPCH:f!);
	copy("$SETTINGS{'TASKS'}/todo/$name_project\_\_$name_-analysis.xml", "$SETTINGS{'DATA'}$PROJECT_PATH{$project_id}/todo/$name_project\_\_$name_-analysis.xml");
	system(qq!Iacls "$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/todo/$name_project\_\_$name_-analysis.xml" /e /g DEPCH:f!);
}
sub GetDataAnalysisList
{
	my $project_id=$_[0];
	my $dir=$_[1];
	$DATA_ANALYSIS_LIST{$project_id}="";	
	@allfiles=();
	system(qq!dir "$dir" > psftp_temp.$ip.log !);
	if (open(IN,"psftp_temp.$ip.log"))
	{
		while($line=<IN>)
		{
			if ($line=~/(\S+\.xml.*)/i) { @allfiles=(@allfiles,$1); }
		}
		close(IN);
	}
	system(qq!del psftp_temp.$ip.log!);
	if (@allfiles>0)
	{   
		foreach $filename (sort @allfiles)
		{
			if ($filename=~/\.xml/i)
			{
				$DATA_ANALYSIS_LIST{$project_id}.="#$filename#"; 
			}
		}
	}
	return $project_id;
}
sub GetReportList
{
	my $project_id=$_[0];
	my $dir=$_[1];
	$REPORT_LIST{$project_id}="";	
	@reportfiles=();
	system(qq!dir "$dir" > psftp_temp.$ip.log !);
	if (open(IN,"psftp_temp.$ip.log"))
	{
		while($line=<IN>)
		{
			if ($line=~/(\S+\.html)/i) { @reportfiles=(@reportfiles,$1); }
		}
		close(IN);
	}
	system(qq!del psftp_temp.$ip.log!);
	if (@reportfiles>0)
	{   
		foreach $filename (sort @reportfiles)
		{
			if ($filename=~/\.html/i)
			{
				$REPORT_LIST{$project_id}.="#$filename#"; 
			}
		}
	}
	return $project_id;
}
sub GetParams
{
	my %params_list=();
	if (open(infile,"../../programs.txt"))
	{
		while($line=<infile>)
		{
			chomp($line); 
			if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/) 
			{
				$params_list{"$1: $2"}="$5";
			}	
		}
		close(infile);
	}
	return(\%params_list);
}
sub GetPrograms
{
	my $programs=$_[0];
	my $programs_dirs=$_[1];
	my $programs_default=$_[2];
	my $programs_params=$_[3];
	my $programs_count=$_[4];
	
	if (open(infile,"../../programs.txt"))
	{
		while($line=<infile>)
		{
			chomp($line);
			if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/) 
			{ 
				${$programs}[$$programs_count]="$1: $2";
				${$programs_dirs}[$$programs_count]="$3";
				${$programs_default}[$$programs_count]="$4";
				${$programs_params}[$$programs_count]="$5";
				$$programs_count++;
			}	
		}
		close(infile);
	}
} 
sub GenerateRandomStringDir
{
	my $length_of_randomstring=32;
	my $reports=$SETTINGS{'REPORTS'};
	my @chars=('a'..'z','A'..'Z','0'..'9','_');
	my $random_string;
	foreach (1..$length_of_randomstring) 
	{
		$random_string.=$chars[rand @chars];
	}
	$reports="$reports"."\/"."$random_string";
	mkdir("$reports"); 
	system(qq!Iacls "$reports" /e /g DEPCH:f!);
	return($reports);
} 
1;