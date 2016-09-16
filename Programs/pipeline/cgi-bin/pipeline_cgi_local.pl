#!c:/perl/bin/perl.exe
require "pipeline_cgi_projexp.pl";
require "pipeline_cgi_results.pl";
print "Content-type: text/html\n\n";
if ($SETTINGS{'DATA'}=~/^\/\//)
{
	use Net::Ping;
	$p = Net::Ping->new();
	if ($p->ping($SETTINGS{'HOST'})) { $p->close(); }
	else { print qq!<font color ='red' size=5><b>Connection to server is currently not available.</b><br></font>\n! ; $p->close(); return; }
}
use File::Copy;
my $ip = $ENV{'REMOTE_ADDR'};
my $status=$query->param("status");
my $project_id=$query->param("project_id");	
if ($project_id!~/\w/) { $project_id=-1; }
my $message="";

if ($status=~/^AddProject$/)
{
	my %names=();
	my $project_name=$query->param("project_name");
	##### all spaces and special characters replaced by _ in names : begin #####
	$project_name=~tr/ /\_/;
	##### end #####	
	open(IN,qq!$SETTINGS{'DATA'}/projects.dat!);
	while($line=<IN>)
	{
		if($line=~/.*\#(.*)$/) 
		{ 
			$names{$1}="1";
		}
	}
	close(IN);
	
	if ($project_name=~/\w/ and $names{$project_name}!~/\w/)
	{
		$project_id=AddProject($project_id,$project_name);
		$message=qq!<font color="#FF0000"><b>Project added</b></font><p>\n!;
	}
	elsif($names{$project_name}=~/\w/)
	{
		$message=qq!<font color="#FF0000"><b>Error: Project name already exists</b></font><p>\n!;
	}
	else
	{
		$message=qq!<font color="#FF0000"><b>Error: Project name is missing</b></font><p>\n!;
	}
	$status="ViewProject";
}
if ($status=~/^ArchiveProject$/)
{
	GetProjects(-1,-1);
	my $project_id_=$PROJECT_PARENT{$project_id};
	ArchiveProject($project_id);
	$project_id=$project_id_; 
	$status="ViewProject"; 
	$message=qq!<font color="#FF0000"><b>Archived project and results</b></font><p>\n!;
}
if ($status=~/^DeleteProject$/)
{
	GetProjects(-1,-1);
	my $project_id_=$PROJECT_PARENT{$project_id};
	DeleteProject($project_id);
	$project_id=$project_id_;
	$status="ViewProject";
	$message=qq!<font color="#FF0000"><b>Project deleted</b></font><p>\n!;
}
print qq!<b><a href="pipeline_cgi.pl?status=ViewProject&project_id=-1">Home</a></b>!;
GetProjects(-1,-1);
$PROJECT_PATH_{$project_id}=$PROJECT_PATH{$project_id}; 
while($PROJECT_PATH_{$project_id}=~s/^\/([^\/]+)//)
{
	my $temp=$1;
	my $proj_id=$PROJECT_ID{$temp};
	print qq!<b>/</b>!;
	if($proj_id!=$project_id)
	{
		print qq!<b><a href="pipeline_cgi.pl?status=ViewProject&project_id=$proj_id">$temp</a></b>!;
	}
	else
	{
		print qq!<b><a href="pipeline_cgi.pl?status=ViewProject&project_id=$proj_id">$PROJECT_NAME{$project_id}</a></b>!;
	}
}
print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b><a href="pipeline_cgi.pl?status=ViewMethods">Methods</a></b>!;
print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b><a href="pipeline_cgi.pl?status=ViewQueue">Queue</a></b>!;
print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b><a href="pipeline_cgi_database.pl?status=CreateDatabase">Database</a></b>!;

################################  Admin Control starts here #######################################
my @names=$query->param;
my $date_time=GetDateTime();
open(OUT,qq!>>../pipeline.log!);
print OUT qq!\nRemote address:$ip\n!;
print OUT qq!Date and Time:$date_time\n!;
foreach my $name (@names) 
{  
	$value = $query->param($name); 
	print OUT qq!$name-$value\n!; 
}
my %ip_add=();
while($SETTINGS{'ADMIN_IPS'}=~s/([^,]+),//)
{
	my $temp=$1;
	$ip_add{$temp}="1"; 
}
if(($ip_add{$ip}=~/\w/) and $status!~/ViewAdmin/ and $status!~/ViewDirStructure/ and $status!~/ViewDemonLog/ and $status!~/ViewPipelineLog/ and $status!~/ViewTaskList/) 
{ 
	print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href="pipeline_cgi.pl?status=ViewAdmin"><b>Admin</b></a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;!;
	$flag=1;
}
print qq!<br><br>!;
if ($status=~/^ViewAdmin$/)
{
	print qq!<a href="pipeline_cgi.pl?status=ViewDirStructure"><b>Directory Structure</b></a><br>\n!;
	print qq!<a href="pipeline_cgi.pl?status=ViewDemonLog"><b>Demon Log</b></a><br>\n!;
	print qq!<a href="pipeline_cgi.pl?status=ViewPipelineLog"><b>Pipeline Log</b></a><br>\n!;
	print qq!<a href="pipeline_cgi.pl?status=ViewTaskList"><b>Task List</b></a><br>\n!;	
	return;
}
if ($status=~/^ViewDirStructure$/)
{
	%project_name=();
	%project_parent=();
	%project_path=();
	if(open(IN,qq!$SETTINGS{'DATA'}/projects.dat!))
	{ 
		while($line=<IN>)
		{
			if($line=~/>([0-9]+)#([^#]+)#(.*)/)
			{
				$project_name{$1}=$3;
				$project_parent{$1}=$2;
			}
		}
		close(IN);
		foreach $value(sort keys %project_name)
		{   
			my $val=$value;
			$project_path{$val}.=qq!#$val#!;
			while($project_parent{$value}!=-1)
			{
				if($project_parent{$value}!=-1)
				{
					$project_path{$val}.=qq!#$project_parent{$value}#!; 
					$value=$project_parent{$value}; 
				}
			}
			$value=0; 
		}
		my @proj_path=();
		foreach my $value(sort keys %project_path)
		{	
			my $i=0;
			my $dir="$SETTINGS{'DATA'}";
			while($project_path{$value}=~s/#([^#]+)#//)
			{
				my $temp=$1;
				$proj_path[$i++]=$temp; 
			} 
			for(my $j=@proj_path-1;$j>=0;$j--)
			{
				print qq!\\!;
				print qq!$project_name{$proj_path[$j]}!;
				$dir.="\/".$project_name{$proj_path[$j]};
			} 
			my $dir_tar=$dir.".tgz"; 
			if(-d $dir) {  }
			elsif(-e $dir_tar) { print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Archived directory!; }
			else {  print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Directory missing!; }
			print qq!<br>!;
			$dir="";
			$dir_tar="";
			@proj_path=();
		}
	}
	return;
}
if ($status=~/^ViewDemonLog$/)
{
	if(open(IN,qq!../demon.log!))
	{
		print qq!<pre>\n!; 
		while($line=<IN>)
		{ 
			print qq!$line!; 
		}
		print qq!</pre>\n!; 
		close(IN);
	}
	return;
}
if ($status=~/^ViewPipelineLog$/)
{
	if(open(IN,qq!../pipeline.log!))
	{
		print qq!<pre>\n!; 
		while($line=<IN>)
		{ 
			$line=~s/\</\&lt;/g;
			$line=~s/\>/\&gt;/g;
			print qq!$line!; 
		}
		print qq!</pre>\n!; 
		close(IN);
	}
	return;
}
if ($status=~/^ViewTaskList$/)
{
	system(qq!tasklist.exe > "../process.log"!);
	if(open(IN,qq!../process.log!))
	{
		print qq!<pre>\n!; 
		while($line=<IN>)
		{
			print qq!$line!; 
		}
		print qq!</pre>\n!; 
		close(IN);
	}
	return;
}
################################  Admin Control ends here #######################################

if ($status=~/^DeleteProjectConfirmation$/)
{
	GetProjects(-1,-1);
	print qq!<b>Are you sure you want to delete this project?<br></b>\n!;
	print qq!
			<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data" style="display:inline;">
			<INPUT TYPE="hidden" NAME="status" VALUE="DeleteProject">
			<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
			<INPUT TYPE="submit" NAME="Yes" VALUE="Yes">
			</FORM>
		!;
	print qq!
			<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data" style="display:inline;">
			<INPUT TYPE="hidden" NAME="status" VALUE="ViewProject">
			<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
			<INPUT TYPE="submit" NAME="No" VALUE="No">
			</FORM>
		!;
}
if ($status=~/^ViewArchive$/)
{
	my $project_archive=$query->param("archive"); 
	my $destination=qq!$SETTINGS{'DATA'}$PROJECT_PATH{$PROJECT_PARENT{$project_id}}!; 
	print qq!
		<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
		<INPUT TYPE="hidden" NAME="status" VALUE="ActivateArchive">
		<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		<INPUT TYPE="hidden" NAME="destination" VALUE="$destination">
		<INPUT TYPE="hidden" NAME="project_archive" VALUE="$project_archive">
		<b>Project and results are archived  </b><INPUT TYPE="submit" NAME="Submit" VALUE="Activate">
	!;
}
if ($status=~/^ActivateArchive$/)
{
	use Archive::Extract;
	use File::Path;
	my $project_archive=$query->param("project_archive"); 
	my $destination=$query->param("destination"); 
	my $extractor = Archive::Extract->new( archive => "$project_archive" );
	my $ok = $extractor->extract( to => "$destination" );
	my $project_name=$project_archive;	
	$project_name=~s/\/\//\//;	
	$project_name=~s/\.tgz//;	
	$project_name=~s/\//\\/g;	
	$destination=~s/\//\\/g;
	$source="$destination"."$project_name"; 
	system(qq!move "$source" "$destination" > log.txt!);
	unlink("log.txt");
	rmtree("$destination/hpc-isilon-a.nyumc.org");
	unlink("$project_archive");
	
	my $destination_res=qq!$SETTINGS{'RESULT'}$PROJECT_PATH{$PROJECT_PARENT{$project_id}}!; 
	my $project_archive_res=qq!$SETTINGS{'RESULT'}$PROJECT_PATH{$PROJECT_PARENT{$project_id}}/$PROJECT_NAME{$project_id}\.tgz!;	
	my $extractor_res = Archive::Extract->new( archive => "$project_archive_res" );
	my $ok_res = $extractor_res->extract( to => "$destination_res" );
	my $project_name_res=$project_archive_res;	
	$project_name_res=~s/\/\//\//;	
	$project_name_res=~s/\.tgz//;	
	$project_name_res=~s/\//\\/g;	
	$destination_res=~s/\//\\/g;
	$source_res="$destination_res"."$project_name_res"; 
	system(qq!move "$source_res" "$destination_res" > log.txt!);
	unlink("log.txt");
	rmtree("$destination_res/hpc-isilon-a.nyumc.org");
	unlink("$project_archive_res");
	$status="ViewProject";
	$message=qq!<font color="#FF0000"><b>Activated projects and results</b></font><p>\n!;
}
if ($message=~/\w/) { print qq!<font color="#FF0000"><b>$message</b></font><p>\n!; }

my $submitexp="";
my $empty_def="";
if ($status=~/^ViewAllProjects$/)
{
	GetProjects(-1,-1); 
	print "<b>All Projects</b><br>\n";
	@list=(); 
	foreach $project_id (keys %PROJECT_NAME)
	{  
		@list=(@list,"\U$PROJECT_PATH{$project_id}#$project_id"); 
	}
	foreach $list (sort @list)
	{
		if ($list=~/.*#([^#]*)$/)
		{
			$project_id=$1;
			print qq!<font size=-1><a href="pipeline_cgi.pl?status=ViewProject&project_id=$project_id">$PROJECT_PATH{$project_id}</a></font> <br>\n!;
		}
	}
}

if ($status=~/^ViewQueue$/)
{
	print qq!<b><i>Queued</i></b><p>!;
	GetDataAnalysisList($project_id,"$SETTINGS{'TASKS'}/todo");
	my $todo=$DATA_ANALYSIS_LIST{$project_id};
	while($todo=~s/^#([^#]+)#//)
	{
		my $job=$1;
		my $job_=$job;
		$job_=~s/\-analysis.xml$//;
		$job_=~s/^(.*)__(.*)$/$1<\/a> ($2)/;
		if ($job_!~/\<\/a\>/) { $job_.="</a>"; }
		print qq!<a href="pipeline_cgi.pl?status=ViewAnalysis&file=$job">$job_<br>!;
	}
	%DATA_ANALYSIS_LIST=();
	
	print qq!<p><b><i>Running</i></b><p>!;
	GetDataAnalysisList($project_id,"$SETTINGS{'TASKS'}/running/$SETTINGS{'DEMON'}");
	my $running=$DATA_ANALYSIS_LIST{$project_id};
	while($running=~s/^#([^#]+)#//)
	{
		my $job=$1;
		my $job_=$job;
		$job_=~s/\-analysis.xml$//;	
		$job_=~s/^(.*)__(.*)$/$1<\/a> ($2)/;
		if ($job_!~/\<\/a\>/) { $job_.="</a>"; }
		print qq!<a href="pipeline_cgi.pl?status=ViewAnalysis&file=$job">$job_<br>!;
	}
	%DATA_ANALYSIS_LIST=();
	
	print qq!<p><b><i>Done</i></b><p>!;
	GetDataAnalysisList($project_id,"$SETTINGS{'TASKS'}/done/$SETTINGS{'DEMON'}");
	my $done=$DATA_ANALYSIS_LIST{$project_id};
	while($done=~s/^#([^#]+)#//)
	{
		$filename=$1; 
		if ($filename=~/^(.*)\.xml\-(.*)$/i) {	$unsorted{$2}=$filename; }
	}
	foreach my $value(reverse sort keys %unsorted) 
	{
		print qq!$value!;
		open(IN,qq!$SETTINGS{'TASKS'}/done/$SETTINGS{'DEMON'}/$unsorted{$value}!);
		while($line=<IN>)
		{
			if($line=~/\<result dir="(.*)"\/\>/) 
			{
				my $path=$1;
				if($path=~/$SETTINGS{'RESULT'}(.*)/) { $folder = $1; print qq!&nbsp;&nbsp;&nbsp;&nbsp;$folder!;}
			}
		}
		if ($unsorted{$value}=~/^(.*\.xml)\-(.*)$/i)
		{
			$job=$1;
			$job=~s/\-analysis.xml$//;
			$job=~s/^(.*)__(.*)$/$1 ($2)/;
			print qq!: $job\n!;
		}
		print qq!<br>!;
	}
	
	%DATA_ANALYSIS_LIST=();
}
if($status=~/^ViewAnalysis/)
{
	my $file=$query->param("file"); 
	if(open(IN,qq!$SETTINGS{'TASKS'}/todo/$file!))
	{
		print qq!<pre>\n!; 
		while($line=<IN>)
		{ 
			$line=~s/\</\&lt;/g;
			$line=~s/\>/\&gt;/g;
			print qq!$line!; 
		}
		print qq!</pre>\n!; 
		close(IN);
	}
	else
	{
		open(IN,qq!$SETTINGS{'TASKS'}/running/$SETTINGS{'DEMON'}/$file!);
		print qq!<pre>\n!; 
		while($line=<IN>)
		{ 
			$line=~s/\</\&lt;/g;
			$line=~s/\>/\&gt;/g;
			print qq!$line!; 
		}
		print qq!</pre>\n!; 
		close(IN);
	}
}
if ($status=~/^ViewMethods$/)
{
	$dir="ID/xtandem.pl";
	my ($one, $two) = GetMethods($dir);
	my @methods = sort{lc $a cmp lc $b}@$one;
	my $count = $two;
	print qq! <b><a href="/pipelines/method_creation.html">Create Methods</a></b>!;
	print qq!<br><br>!; 
	print qq! <b>List of existing methods</b><br><br>!; 
	print qq! <b>Active Methods</b><br>!; 
	for(my $i=0;$i<$count;$i++)
	{
		print qq!<a href="pipeline_cgi.pl?status=GetMethods&method_id=$i&method_dir=xtandem"><font color="0000FF">$methods[$i]</a></font><br>!;
		system(qq!del $methods[$i]!);
	}
	print qq!<hr width=75% align=left>!;
	print qq!<b>Inactive Methods</b><br>!;
	$dir="";
	$dir="ID/xtandem.pl/inactive";
	my ($one_, $two_) = GetMethods($dir);
	my @methods_ = sort{lc $a cmp lc $b}@$one_;
	my $count_ = $two_;
	for(my $i=0;$i<$count_;$i++)
	{
		print qq!<a href="pipeline_cgi.pl?status=GetMethods&method_id=$i&method_dir=inactive"><font color="000000">$methods_[$i]</a><br>!;
		system(qq!del $methods_[$i]!);
	}
}
if ($status=~/^GetMethods$/)   
{
	my $i=$query->param("method_id");
	my $method_dir=$query->param("method_dir");
	if($method_dir=~/xtandem/)
	{
		$dir="ID/xtandem.pl";
		my ($one, $two) = GetMethods($dir);
		my @methods = sort{lc $a cmp lc $b} @$one;
		copy("$SETTINGS{'TASKS'}/methods/$dir/$methods[$i]", "D:/Programs/pipeline/cgi-bin");
		print qq!
			<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
			<INPUT TYPE="hidden" NAME="status" VALUE="InactivateMethods">
			<INPUT TYPE="hidden" NAME="method_id" VALUE="$i">
			<p>
		!;
		
		print qq!<a href="/pipelines/$methods[$i]">$methods[$i]</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;!;
		print qq!<INPUT TYPE="submit" NAME="Submit" VALUE="Inactivate"><br><FORM>\n!;
	}	
	if($method_dir=~/inactive/)
	{
		$dir="ID/xtandem.pl/inactive";
		my ($one, $two) = GetMethods($dir);
		my @methods = sort{lc $a cmp lc $b} @$one; 
		copy("$SETTINGS{'TASKS'}/methods/$dir/$methods[$i]", "D:/Programs/pipeline/cgi-bin");
		print qq!
			<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
			<INPUT TYPE="hidden" NAME="status" VALUE="ActivateMethods">
			<INPUT TYPE="hidden" NAME="method_id" VALUE="$i">
			<p>
		!;
		
		print qq!<a href="/pipelines/$methods[$i]">$methods[$i]</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;!;
		print qq!<INPUT TYPE="submit" NAME="Submit" VALUE="Activate"><br><FORM>\n!;
	}	
}
if ($status=~/^ActivateMethods$/)
{
	my $i=$query->param("method_id");
	$dir="ID/xtandem.pl/inactive";
	my $dir1="ID/xtandem_cluster.pl/inactive";
	my ($one, $two) = GetMethods($dir);
	my @methods = sort{lc $a cmp lc $b} @$one; 
	move("$SETTINGS{'TASKS'}/methods/$dir/$methods[$i]","$SETTINGS{'TASKS'}/methods/ID/xtandem.pl");
	move("$SETTINGS{'TASKS'}/methods/$dir1/$methods[$i]","$SETTINGS{'TASKS'}/methods/ID/xtandem_cluster.pl");
	system(qq!del "$methods[$i]"!);
	$dir="ID/xtandem.pl";
	my ($one, $two) = GetMethods($dir);
	my @methods = sort{lc $a cmp lc $b} @$one;
	my $count = $two; 
	print qq! <b>Active Methods</b><br>!; 
	for(my $i=0;$i<$count;$i++)
	{
		print qq!<a href="pipeline_cgi.pl?status=GetMethods&method_id=$i&method_dir=xtandem"><font color="0000FF">$methods[$i]</a></font><br>!;
	}
	print qq!<hr width=75% align=left>!;
	print qq!<b>Inactive Methods</b><br>!;
	$dir="";
	$dir="ID/xtandem.pl/inactive";
	my ($one_, $two_) = GetMethods($dir);
	my @methods_ = sort{lc $a cmp lc $b} @$one_;
	my $count_ = $two_;
	for(my $i=0;$i<$count_;$i++)
	{
		print qq!<a href="pipeline_cgi.pl?status=GetMethods&method_id=$i&method_dir=inactive"><font color="000000">$methods_[$i]</a></font><br>!;
	}
}
if ($status=~/^InactivateMethods$/)
{
	my $i=$query->param("method_id");
	$dir="ID/xtandem.pl";
	my $dir1="ID/xtandem_cluster.pl";
	my ($one, $two) = GetMethods($dir);
	my @methods = sort{lc $a cmp lc $b} @$one; 
	move("$SETTINGS{'TASKS'}/methods/$dir/$methods[$i]","$SETTINGS{'TASKS'}/methods/ID/xtandem.pl/inactive");
	move("$SETTINGS{'TASKS'}/methods/$dir1/$methods[$i]","$SETTINGS{'TASKS'}/methods/ID/xtandem_cluster.pl/inactive");
	system(qq!del "$methods[$i]"!);
	$dir="ID/xtandem.pl";
	my ($one, $two) = GetMethods($dir);
	my @methods = sort{lc $a cmp lc $b} @$one;
	my $count = $two; 
	print qq! <b>Active Methods</b><br>!; 
	for(my $i=0;$i<$count;$i++)
	{
		print qq!<a href="pipeline_cgi.pl?status=GetMethods&method_id=$i&method_dir=xtandem"><font color="0000FF">$methods[$i]</a></font><br>!;
	}
	print qq!<hr width=75% align=left>!;
	print qq!<b>Inactive Methods</b><br>!;
	$dir="";
	$dir="ID/xtandem.pl/inactive";
	my ($one_, $two_) = GetMethods($dir);
	my @methods_ = sort{lc $a cmp lc $b} @$one_;
	my $count_ = $two_;
	for(my $i=0;$i<$count_;$i++)
	{
		print qq!<a href="pipeline_cgi.pl?status=GetMethods&method_id=$i&method_dir=inactive"><font color="000000">$methods_[$i]</a></font><br>!;
	}
}

if ($status=~/^DefineExperiment$/)
{
	my $project_id=$query->param("project_id");
	my $name=$query->param("definition_name"); 
	my $count=0;
	my %sample_files=();
	my %list=();
	GetProjects($project_id,-1);
	GetExperimentFiles($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}");
	my $tem=$EXPERIMENT_DEFINITIONS{$project_id};
	while ($tem=~s/^#([^#]+)#//)
	{
		my $val=$1;
		$val=~s/\-experiment\.xml//;
		$list{$val}="1"; 
	}
	
	if ($name=~/\w/ and $list{$name}!~/\w/)
	{
		for(my $file=0;$file<$EXPERIMENT_FILES_COUNT{$project_id};$file++)
		{
			if ($query->param("include$file")=~/\w/)  
			{
				$count++;
				my $temp=$EXPERIMENT_FILES{$project_id};
				while ($temp=~s/^#([^#]+)#//)
				{
					my $name_=$1;
					if ($query->param("include$file")=~$name_)
					{
						$sample_files{$query->param("include$file")}="1";
					}
				}
			}
		}
		if ($count==0)
		{
			print qq!<font color="#FF0000"><b>Error: No files have been selected</b></font><p>\n!;
			$status="DefineExperimentForm";
		}
		else
		{
			AddExperimentDefinition($project_id,$name,\%sample_files);
			print qq!<font color="#FF0000"><b>Experiment definition added</b></font><p>\n!;
			$status="ViewProject";
		}
	}
	elsif($list{$name}=~/\w/)
	{
		$error="yes"; 
		print qq!<font color="#FF0000"><b>Error: Experiment definition name already exists</b></font><p>\n!;
		$status="DefineExperimentForm";		
	}
	else
	{
		$error="yes"; 
		print qq!<font color="#FF0000"><b>Error: Experiment definition is missing</b></font><p>\n!;
		$status="DefineExperimentForm";
	}
}

if ($status=~/^DefineExperimentForm$/)
{
	my $project_id=$query->param("project_id");
	my $name=$query->param("definition_name");
	##### all spaces and special characters replaced by _ in names : begin #####
	$name=~tr/ /\_/;
	##### end #####	
	GetProjects($project_id,-1);
	GetExperimentFiles($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}");	
	print qq!
		<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
		<INPUT TYPE="hidden" NAME="status" VALUE="DefineExperimentForm">
		<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		<INPUT TYPE="submit" NAME="Submit" VALUE="All">
		<INPUT TYPE="submit" NAME="Submit" VALUE="None">
	!;
	my $files=$EXPERIMENT_FILES{$project_id};
	my $file_count_raw=0;
	my $file_count_mgf=0;
	my $file_count_mzXML=0;
	while($files=~s/^#([^#]+)#//)
	{
		my $file=$1;
		if ($file=~/\.raw$/i and $file_count_raw==0) { print qq! <INPUT TYPE="submit" NAME="Submit" VALUE="Raw"> !; $file_count_raw++; }
		if ($file=~/\.mgf$/i and $file_count_mgf==0) { print qq! <INPUT TYPE="submit" NAME="Submit" VALUE="MGF">!; $file_count_mgf++;}
		if ($file=~/\.mzXML$/i and $file_count_mzXML==0) { print qq! <INPUT TYPE="submit" NAME="Submit" VALUE="mzXML">!; $file_count_mzXML++;}
	}
	print qq!
		</FORM>
	!;
	
	my $what=$query->param("Submit");
	print qq!
		<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
		<INPUT TYPE="hidden" NAME="status" VALUE="DefineExperiment">
		<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		<font size=-1><b>Name:</b> <INPUT TYPE="text" NAME="definition_name" VALUE="$name">
		<p>
	!;
	
	my $files=$EXPERIMENT_FILES{$project_id};
	my $count=0;
	while($files=~s/^#([^#]+)#//)
	{
		my $file=$1;
		print qq!Include <input type="checkbox" name="include$count" value="$file"!;
		if ($what=~/Define/ or $what=~/All/) { print qq! checked!; }
		else
		{
			if ($file=~/\.raw$/i and $what=~/Raw/) { print qq! checked!; }
			if ($file=~/\.mgf$/i and $what=~/MGF/) { print qq! checked!; }
			if ($file=~/\.mzXML$/i and $what=~/mzXML/) { print qq! checked!; }
		}
		print qq!>!;
		print qq!&nbsp;&nbsp;&nbsp;$file<br>!;
		$count++;
	}
	print qq!
		<p><INPUT TYPE="submit" NAME="Submit" VALUE="Define Experiment"></font>
		</FORM>
	!;
}

if ($status=~/^SubmitJob$/)
{
	my $project_id=$query->param("project_id");
	my $name=$query->param("name");
	my $name_project=$query->param("name_project");
	my @step=();
	my $step="";
	my @method=();
	my @methods=();
	my @delete=();   
	my $steps=0;
	my $check_delete="";
	GetProjects($project_id,-1);
	GetExperimentFiles($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}");
	for(my $i=0;$i<10;$i++)
	{
		$step=$query->param("step$i");
		$method[$i]=$query->param("method_$i");
		if ($step=~/\w/) 
		{
			my $i_=$i+1;
			$step[$steps]= $step;
			$methods[$steps]= $method[$i]; 
			$check_delete=$query->param("delete$i");
			if($check_delete eq "on") {	$delete[$steps]=1; }
			else { $delete[$steps]= 0; }
			$steps++;					
		}
	}
	AddAnalysisDefinition($project_id,$name,\@step,$steps,\@methods,$name_project,\@delete);
	print qq!<b><font color="#FF0000">Data analysis submitted</font></b><p>\n!;
	$status="ViewProject";
}

if ($status=~/^ViewProject$/ or $status!~/\w/)
{   
	print qq!
		<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
		<INPUT TYPE="hidden" NAME="status" VALUE="AddProject">
		<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
	!;
	print qq!<b>Projects</b>&nbsp;&nbsp;&nbsp;
		<INPUT TYPE="submit" NAME="Submit" VALUE="Add">
		<font size=-1><b>Name:</b> <INPUT TYPE="text" NAME="project_name" VALUE=""></font></FORM>
	!;
	@list=();
	foreach $project_id_ (keys %PROJECT_NAME)
	{ 
		if ($project_id==$PROJECT_PARENT{$project_id_})
		{
			@list=(@list,"\U$PROJECT_NAME{$project_id_}#$project_id_"); 
		}
	}
	foreach $list (sort @list)
	{
		if ($list=~/.*#([^#]*)$/)
		{
			$project_id_=$1;
			$project_archived="$SETTINGS{'DATA'}$PROJECT_PATH{$PROJECT_PARENT{$project_id_}}/$PROJECT_NAME{$project_id_}"."\.tgz"; 
			if(-e $project_archived)
			{
				print qq!<a href="pipeline_cgi.pl?status=ViewArchive&project_id=$project_id_&archive=$project_archived"><font size=-1 color="black">$PROJECT_NAME{$project_id_}</a></font> <br>\n!;
			}
			else
			{
				print qq!<font size=-1><a href="pipeline_cgi.pl?status=ViewProject&project_id=$project_id_">$PROJECT_NAME{$project_id_}</a></font> <br>\n!;
			}
		}
	}
	print qq!<hr width=75% align=left>!; 
	if ($project_id>=0 and $PROJECT_PARENT{$project_id}>=0) { $status="ViewExperiment"; }
}
# if ($status=~/^DefineExperimentForm$/)
# {
	# my $project_id=$query->param("project_id");
	# GetProjects($project_id,-1);
	# GetExperimentFiles($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}");
	# print qq!<b><a href="pipeline_cgi.pl?status=ViewProject&project_id=$PROJECT_PARENT{-1}">Home</a></b>!;
	# $PROJECT_PATH_{$project_id}=$PROJECT_PATH{$project_id};
	# while($PROJECT_PATH_{$project_id}=~s/^\/([^\/]+)//)
	# {
		# my $temp=$1;
		# my $proj_id=$PROJECT_ID{$temp};
		# print qq!<b>/</b>!;
		# print qq!<b><a href="pipeline_cgi.pl?status=ViewProject&project_id=$proj_id">$temp</a></b>!;
	# }
	# print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b><a href="pipeline_cgi.pl?status=ViewMethods">Methods</a></b>!;
	# print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b><a href="pipeline_cgi.pl?status=ViewQueue">Queue</a></b><br><br>!;
	# #print qq! (<a href="pipeline_cgi.pl?status=ViewExperiment&experiment_id=$experiment_id&project_id=$project_id">back)</a><p></font>\n!;
	# print qq!
		# <FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
		# <INPUT TYPE="hidden" NAME="status" VALUE="DefineExperiment">
		# <INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		# <font size=-1><b>Name:</b> <INPUT TYPE="text" NAME="definition_name" VALUE="">
		# <p>
	# !;
	# my $files=$EXPERIMENT_FILES{$project_id};
	# my $count=0;
	# while($files=~s/^#([^#]+)#//)
	# {
		# my $file=$1;
		# print qq!Group: <select name="group_$count">!;
		# for(my $i=1;$i<=$EXPERIMENT_FILES_COUNT{$project_id};$i++)
		# {
			# if ($i==1) { print qq!<option selected> $i\n!; } else { print qq!<option> $i\n!; }
		# }
		# print qq!</select>!;
		# print qq!&nbsp;&nbsp;&nbsp;Sample: <select name="sample_$count">!;
		# print qq!<option>\n!;
		# for(my $i=1;$i<=$EXPERIMENT_FILES_COUNT{$project_id};$i++)
		# {
			# if ($i==$count+1) { print qq!<option selected> $i\n!; } else { print qq!<option> $i\n!; }
		# }
		# print qq!</select>!;
		# print qq!&nbsp;&nbsp;&nbsp;$file<br>!;
		# $count++;
	# }
	# print qq!
		# <p><INPUT TYPE="submit" NAME="Submit" VALUE="Define Experiment"></font>
		# </FORM>
	# !;
# }

# if ($status=~/^DefineExperiment$/)
# {
	# my $project_id=$query->param("project_id");
	# my $name=$query->param("definition_name"); 
	# my $group=0;
	# my $sample=0;
	# my $file=0;
	# my %group_samples=();
	# my %sample_files=();
	# GetProjects($project_id,-1);
	# GetExperimentFiles($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}");
	# if ($name=~/\w/)
	# {
		# for($file=0;$file<$EXPERIMENT_FILES_COUNT{$project_id};$file++)
		# {
			# $group=$query->param("group_$file");
			# $sample=$query->param("sample_$file");
			# if ($group=~/\w/ and $sample=~/\w/) 
			# {
				# $group_samples{$group}.="#$sample#";
				# $sample_files{$sample}.="#$file#";
			# }
		# }
		# AddExperimentDefinition($project_id,$name,\%group_samples,\%sample_files);
		# $submitexp="yes";
		# $status="ViewExperiment";
	# }
	# else
	# {
		# $error="yes"; 
		# print qq!<font color="#FF0000"><b>Error: Experiment definition is missing</b></font><p>\n!;
		# print qq! (<a href="pipeline_cgi.pl?status=DefineExperimentForm&project_id=$project_id">back</a></font>)!;
	# }
# }


if ($status=~/^SubmitJobFormMethods$/)
{
	GetProjects($project_id,-1);
	my $project_id=$query->param("project_id");
	my $name=$query->param("experiment_definition");
	my $name_project=$query->param("name_project");
	print qq!
		<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
		<INPUT TYPE="hidden" NAME="status" VALUE="SubmitJob">
		<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		<INPUT TYPE="hidden" NAME="name" VALUE="$name">
	!;
	my $name__=$name;
	$name__=~s/\-experiment\.xml//;
	print qq!
		<b>Data Analysis: $name_project <br> </b>\n
		<b>Experiment Definition: $name__<p> </b>\n
	!;
	my @step=();
	my $point=0;
	GetExperimentFiles($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}");
	my $val = GetParams();
	my %params_list = %$val;
	for(my $i=0;$i<=10;$i++)
	{
		$steps=$query->param("step$i");
		print qq!<INPUT TYPE="hidden" NAME="step$i" VALUE="$steps">\n!;
		if ($steps=~/\w/) 
		{  
			my $i_=$i+1;
			print qq!Step $i_. $steps \n!;
			my $dir=$steps;
			$dir=~s/\: /\//;
			my ($one, $two) = GetMethods($dir);
			my @methods = @$one;
			my $count = $two;
			if ($count>0)
			{
				print qq! <select name="method_$i">!;
				print qq!<option>\n!;
				for(my $j=0;$j<$count;$j++)
				{
					print qq!<option  value="$dir/$methods[$j]"> $methods[$j]\n!;
				}
				print qq!</select>!;
			}
			else
			{
				print qq!<INPUT TYPE="text" NAME="method_$i" VALUE='$params_list{$steps}'>!;
			}
			$step[$point]= $steps;
			$point++;
			if (open(infile,"../../programs.txt"))
			{
				while($line=<infile>)
				{
					chomp($line);
					if ($line=~/^([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]*)\t([^\t]*)$/) 
					{ 
						my $programs="$1: $2";
						my $delete=$6;
						if($steps eq $programs and $delete =~/\w/) 
						{
							print qq!&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp&nbsp!;
							print qq!Delete <input type="checkbox" name="delete$i" value="on"!;
							if ($programs=~/^Create mzXML/i or $programs=~/^Create MGF/i) { print qq! checked!; }
							print qq!><br>\n!;
						}
						elsif($steps eq $programs and $delete !~/\w/)  { print qq!<br>\n!;} 
					}	
				}
				close(infile);
			}
		} 
		
	}
	print qq!
		<p>
		<INPUT TYPE="hidden" NAME="name_project" VALUE="$name_project">
		<INPUT TYPE="submit" NAME="Submit" VALUE="Submit Job"></font>
		</FORM>
	!;
}
if ($status=~/^SubmitJobFormSteps$/)
{
	my $project_id=$query->param("project_id");
	my $empty_def=$query->param("empty_def");
	GetProjects($project_id,-1);
	GetExperimentFiles($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}"); 
	if($empty_def eq "yes")
	{
		print qq!<font color="#FF0000"><b>Error: Experiment definitions are missing in this project</b></font>&nbsp;&nbsp;!;
		print qq! (<a href="pipeline_cgi.pl?status=ViewProject&project_id=$project_id">back)</a><br><br>\n</font>!;
		$empty_def=""; 
		return;
	}
	print qq!
		<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
		<INPUT TYPE="hidden" NAME="status" VALUE="SubmitJobSteps">
		<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		<p>
	!;
	print qq!
		<b>Data Analysis Name: <INPUT TYPE="text" NAME="name_project" VALUE="$name_project"></b></font>
	!;
	print qq!<p><b>Experiment Definition: <select name="experiment_definition"></b><p>!;
	my $definition=$EXPERIMENT_DEFINITIONS{$project_id};
	while($definition=~s/^#([^#]+)#//)
	{
		$file=$1;
		$file=~s/\-experiment\..*//;
		print qq!<option> $file\n!;
	}
	print qq!</select><p>!;
	print qq!
		<p><INPUT TYPE="submit" NAME="Submit" VALUE="Continue"></font>
		</FORM>
	!;
}
if ($status=~/^SubmitJobSteps$/)
{
	my $line="";
	my $file="";
	my $project_id=$query->param("project_id");
	my $name=$query->param("experiment_definition");
	$name=$name."\-experiment.xml";
	my $name_project=$query->param("name_project");	
	##### all spaces and special characters replaced by _ in names : begin #####
	$project_name=~tr/ /\_/;
	##### end #####	
	GetProjects($project_id,-1);
	GetExperimentFiles($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}"); 
	my %analysis=();
	GetDataAnalysisList($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/todo/$SETTINGS{'DEMON'}");
	my $todo=$DATA_ANALYSIS_LIST{$project_id};
	while($todo=~s/^#([^#]+)#//)
	{
		$filename=$1; 
		if ($filename=~/^(.*)\.xml\-(.*)$/i)
		{
			$name_date=$2;
			if($name_date=~/^([^\-]+)\-([0-9\-]+)$/) { $analysis{$1}="1"; }
		}
	}
	%DATA_ANALYSIS_LIST=();
	GetDataAnalysisList($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/running/$SETTINGS{'DEMON'}");
	my $running=$DATA_ANALYSIS_LIST{$project_id};
	while($running=~s/^#([^#]+)#//)
	{
		$filename=$1; 
		if ($filename=~/^(.*)\.xml\-(.*)$/i)
		{
			$name_date=$2;
			if($name_date=~/^([^\-]+)\-([0-9\-]+)$/) { $analysis{$1}="1"; }
		}
	}
	%DATA_ANALYSIS_LIST=();
	GetDataAnalysisList($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/done/$SETTINGS{'DEMON'}");
	my $done=$DATA_ANALYSIS_LIST{$project_id};
	while($done=~s/^#([^#]+)#//)
	{
		$filename=$1; 
		if ($filename=~/^(.*)\.xml\-(.*)$/i)
		{
			$name_date=$2;
			if($name_date=~/^([^\-]+)\-([0-9\-]+)$/) { $analysis{$1}="1"; }
		}
	}
	%DATA_ANALYSIS_LIST=();
	if ($name_project=~/\w/ and $analysis{$name_project}!~/\w/)
	{
		print qq!
			<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
			<INPUT TYPE="hidden" NAME="status" VALUE="SubmitJobFormMethods">
			<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
			<INPUT TYPE="hidden" NAME="experiment_definition" VALUE="$name">
		!;
		my $name__=$name;
		$name__=~s/\-experiment\.xml//;
		print qq!
			<b>Data Analysis: $name_project <br> </b>\n
			<b>Experiment Definition: $name__<br><br> </b>\n
		!;
		open(IN,qq!$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/$name!);
		while($line=<IN>)
		{
			if ($line=~/\<file path.*\.([A-Za-z]+)"/) { $file = $1; }
		}
		close(IN);
		my @programs=();
		my @programs_dirs=();
		my @programs_default=();
		my @programs_params=();
		my $programs_count=0;
		GetPrograms(\@programs,\@programs_dirs,\@programs_default,\@programs_params,\$programs_count);
		for(my $i=0;$i<$programs_count;$i++)
		{
			my $i_=$i+1;
			print qq!Step $i_. <select name="step$i">!; 
			$selected_=0;
			for(my $j=0;$j<$programs_count;$j++)
			{
				$selected="";
				if ($file =~/RAW/i) 
				{
					if ($i_ == 1 and $programs[$j]=~/^Create mzXML:/ and $programs_default[$j]=~/^\*$/) { $selected=" selected"; $selected_=1; }
					if ($i_ == 2 and $programs[$j]=~/^QC: .*_mzxml_.*$/i) { $selected=" selected"; $selected_=1; }
					if ($i_ == 3 and $programs[$j]=~/^Create MGF/ and $programs_default[$j]=~/^\*$/) { $selected=" selected"; $selected_=1; }
					if ($i_ == 4 and $programs[$j]=~/^ID:/  and $programs_default[$j]=~/^\*$/) { $selected=" selected"; $selected_=1; }
				}
				elsif ($file =~/MGF/i) 
				{
					if ($i_ == 1 and $programs[$j]=~/^QC: .*_mgf_.*$/) { $selected=" selected"; $selected_=1; }
					if ($i_ == 2 and $programs[$j]=~/^ID:/  and $programs_default[$j]=~/^\*$/) { $selected=" selected"; $selected_=1; }
				}
				elsif ($file =~/MZXML/i) 
				{
					if ($i_ == 1 and $programs[$j]=~/^QC: .*_mzxml_.*$/) { $selected=" selected"; $selected_=1; }
					if ($i_ == 2 and $programs[$j]=~/^Create MGF/ and $programs_default[$j]=~/^\*$/) { $selected=" selected"; $selected_=1; }
					if ($i_ == 3 and $programs[$j]=~/^ID:/  and $programs_default[$j]=~/^\*$/) { $selected=" selected"; $selected_=1; }
				}
				if($programs[$j] !~/^Cleanup: del_exp.pl/)
				{
					print qq!<option$selected> $programs[$j]\n!;
				}
			}
			if ($selected_==0) { print qq!<option selected>\n!; } else { print qq!<option>\n!; }
			print qq!</select><p>!;
		} 
		print qq!
			<p><INPUT TYPE="submit" NAME="Submit" VALUE="Continue"></font>
			<INPUT TYPE="hidden" NAME="name_project" VALUE="$name_project">
			</FORM>
		!;
	}
	elsif($analysis{$name_project}=~/\w/)
	{
		print qq!<font color="#FF0000"><b>Error: Data analysis name already exists</b></font><p>\n!;	
		print qq! (<a href="pipeline_cgi.pl?status=SubmitJobFormSteps&project_id=$project_id">back</a></font>)!; 
	}
	else
	{
		print qq!<font color="#FF0000"><b>Error: Data analysis name is missing</b></font><p>\n!;	
		print qq! (<a href="pipeline_cgi.pl?status=SubmitJobFormSteps&project_id=$project_id">back</a></font>)!; 
	}
}
if ($status=~/^ViewExperiment$/)
{
	GetProjects($project_id,-1);
	GetExperimentFiles($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}");
	if($submitexp eq "yes") 
	{ 
		print qq!<p><b><font color="#FF0000">Experiment defined</font></b><p><br>!; 
		$submitexp="";
		print qq!<b><a href="pipeline_cgi.pl?status=ViewProject&project_id=$PROJECT_PARENT{$project_id}">Home</a></b>!;
		if ($project_id!~/\w/) { $project_id=-1; }
		GetProjects(-1,-1);
		$PROJECT_PATH_{$project_id}=$PROJECT_PATH{$project_id};
		while($PROJECT_PATH_{$project_id}=~s/^\/([^\/]+)//)
		{
			my $temp=$1;
			my $proj_id=$PROJECT_ID{$temp};
			print qq!<b>/</b>!;
			if($proj_id!=$project_id)
			{
				print qq!<b><a href="pipeline_cgi.pl?status=ViewProject&project_id=$proj_id">$temp</a></b>!;
			}
			else
			{
				print qq!<b><a href="pipeline_cgi.pl?status=ViewProject&project_id=$proj_id">$PROJECT_NAME{$project_id}</a></b>!;
			}
		}
		print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b><a href="pipeline_cgi.pl?status=ViewMethods">Methods</a></b>!;
		print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b><a href="pipeline_cgi.pl?status=ViewQueue">Queue</a></b><br><br>!;
		print qq!<br>\n!;
	}
	if ($EXPERIMENT_FILES{$project_id}=~/\w/)
	{
		print qq!
			<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
			<INPUT TYPE="hidden" NAME="status" VALUE="DefineExperimentForm">
			<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		!;

		if ($EXPERIMENT_DEFINITIONS{$project_id}=~/\w/)
		{
			print qq!<p><b>Experiment Definitions</b>&nbsp;&nbsp;!;
			print qq!<INPUT TYPE="submit" NAME="Submit" VALUE="Define">\n!;
		}
		else
		{
			print qq!<p><b><i><font color="#FF0000">Define Experiment</font></i></b>&nbsp;&nbsp;!;
			print qq!<INPUT TYPE="submit" NAME="Submit" VALUE="Define">\n!;
			print qq!&nbsp;&nbsp;&nbsp;<img src="/pipelines/method/red-arrow.jpg">\n!;
		}
		print qq!</FORM>\n!;
		my $definition=$EXPERIMENT_DEFINITIONS{$project_id};
		if($definition!~/\w/) { $empty_def="yes"; }
		my $i=0;
		while($definition=~s/^#([^#]+)#//)
		{
			$file[$i]=$1;
			$file[$i]=~s/\-experiment\..*//; 
			$i++;
		}
		@sorted_file=sort{lc $a cmp lc $b}@file;
		for(my $j=0;$j<$i;$j++)
		{
			print qq!<a href="pipeline_cgi.pl?status=GetExperiment&file=$sorted_file[$j]&project_id=$project_id">$sorted_file[$j]</a><br>!;
		}	
		print qq!<hr width=75% align=left>!;
	}

	if ($EXPERIMENT_DEFINITIONS{$project_id}=~/\w/)
	{
		print qq!
			<p>
			<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
			<INPUT TYPE="hidden" NAME="status" VALUE="SubmitJobFormSteps">
			<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
			<INPUT TYPE="hidden" NAME="empty_def" VALUE="$empty_def">
		!;

		my $found=0;
		%DATA_ANALYSIS_LIST=();
		GetDataAnalysisList($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/todo/$SETTINGS{'DEMON'}");
		if ($DATA_ANALYSIS_LIST{$project_id}=~/\w/) { $found=1; }
		GetDataAnalysisList($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/running/$SETTINGS{'DEMON'}");
		if ($DATA_ANALYSIS_LIST{$project_id}=~/\w/) { $found=1; }
		GetDataAnalysisList($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/done/$SETTINGS{'DEMON'}");
		if ($DATA_ANALYSIS_LIST{$project_id}=~/\w/) { $found=1; }
		if ($found==1)
		{	
			print qq!<p><b>Data Analysis</b>&nbsp;&nbsp;!;
			print qq!<INPUT TYPE="submit" NAME="Submit" VALUE="Submit"></font>\n!;
		}
		else
		{	
			print qq!<p><b><i><font color="#FF0000">Submit Analysis</font></i></b>&nbsp;&nbsp;!;
			print qq!<INPUT TYPE="submit" NAME="Submit" VALUE="Submit"></font>\n!;
			print qq!&nbsp;&nbsp;&nbsp;<img src="/pipelines/method/red-arrow.jpg">\n!;
		}
		print qq!</FORM>!;
		GetDataAnalysisList($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/todo/$SETTINGS{'DEMON'}");
		my $todo=$DATA_ANALYSIS_LIST{$project_id};
		if ($todo=~/\w/) { print qq!<p><i><b>Queued</b></i><br>!; }
		while($todo=~s/^#([^#]+)#//)
		{
			$file_=$1;
			print qq!
				<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
				<INPUT TYPE="hidden" NAME="status" VALUE="DeleteAnalysisFile">
				<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
				<INPUT TYPE="hidden" NAME="filename" VALUE="$file_">
				<INPUT TYPE="hidden" NAME="dir" VALUE="todo">
			!;
			my $file__=$file_;
			$file__=~s/\-analysis.xml$//;
			$file__=~s/^(.*)__(.*)$/$1<\/a> ($2)/;
			if ($file__!~/\<\/a\>/) { $file__.="</a>"; }
			print qq!<a href="pipeline_cgi.pl?status=ViewAnalysis&file=$file_"><font color="#FF0000">$file__</font>\n!;
			print qq!
				<INPUT TYPE="submit" NAME="Submit" VALUE="Delete"></font>
				</FORM>
			!;
		}
		%DATA_ANALYSIS_LIST=();
	
		GetDataAnalysisList($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/running/$SETTINGS{'DEMON'}");
		my $running=$DATA_ANALYSIS_LIST{$project_id};
		if ($running=~/\w/) { print qq!<p><i><b>Running</b></i><br>!; }
		while($running=~s/^#([^#]+)#//)
		{
			$file_=$1;
			print qq!
				<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
				<INPUT TYPE="hidden" NAME="status" VALUE="DeleteAnalysisFile">
				<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
				<INPUT TYPE="hidden" NAME="filename" VALUE="$file_">
				<INPUT TYPE="hidden" NAME="dir" VALUE="running">
			!;
			my $file__=$file_;
			$file__=~s/\-analysis.xml$//;
			$file__=~s/^(.*)__(.*)$/$1<\/a> ($2)/;
			if ($file__!~/\<\/a\>/) { $file__.="</a>"; }
			print qq!<font color="#FF0000">$file__</font>\n!;
			print qq!
				<INPUT TYPE="submit" NAME="Submit" VALUE="Delete"></font>
				</FORM>
			!;
		}
		%DATA_ANALYSIS_LIST=();
	
		GetDataAnalysisList($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/done/$SETTINGS{'DEMON'}");
		my $done=$DATA_ANALYSIS_LIST{$project_id};
		if ($done=~/\w/) 
		{  
			print qq!
				<FORM ACTION="pipeline_cgi_reports.pl" METHOD="post" ENCTYPE="multipart/form-data">
			!;
			print qq!<p><i><b>Done</b></i>!; 
			if($DATA_ANALYSIS_COUNT==1)
			{
				if($done=~/^#([^#]+)#/) 
				{  
					my $file_name=$1;
					if ($file_name=~/^(.*)\.xml\-(.*)$/i)
					{
						$xml_name=$1;
						$name_date=$2;
						$name=$xml_name;
						$name=~s/\-analysis$//;
						$name=~s/^(.*)__(.*)$/$1 ($2)/;
					}
				}
				print qq!
					<INPUT TYPE="hidden" NAME="status" VALUE="CreateReportStep2">
					<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
					<INPUT TYPE="hidden" NAME="name" VALUE="$name">
					<INPUT TYPE="submit" NAME="Submit" VALUE="Report"></font>
					</FORM>
				!;
			}
			else
			{
				print qq!
					<INPUT TYPE="hidden" NAME="status" VALUE="CreateReportStep1">
					<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
					<INPUT TYPE="submit" NAME="Submit" VALUE="Report"></font>
					</FORM>
				!;
			} 
		}
		while($done=~s/^#([^#]+)#//)
		{
			$filename=$1; 
			if ($filename=~/^(.*)\.xml\-(.*)$/i)
			{
				$xml_name=$1;
				$name_date=$2;
				$name=$xml_name;
				$name=~s/\-analysis$//;
				$name=~s/^(.*)__(.*)$/$1<\/a> ($2)/;
				if ($name!~/\<\/a\>/) { $name.="</a>"; }
				print qq!<a href="pipeline_cgi.pl?dataanalysis_date=$name_date&dataanalysis_name=$xml_name&status=DataAnalysisProgramList&project_id=$project_id">$name<br>!; 
			}
		}
		%DATA_ANALYSIS_LIST=();
		print qq!<hr width=75% align=left>!; 
	}
	my $files=$EXPERIMENT_FILES{$project_id};
	if ($files=~/\w/)
	{
		print qq!<p><b>Data Files</b>!;
		print qq! (Data files in $PROJECT_PATH{$project_id} on Isilon)<p>!;
	}
	else
	{
		print qq!<b><i><font color="#FF0000">Upload data files to $PROJECT_PATH{$project_id} on Isilon</font></i></b>!;
		print qq!&nbsp;&nbsp;&nbsp;<img src="/pipelines/method/red-arrow.jpg"><p>\n!;
	}
	while($files=~s/^#([^#]+)#//)
	{
		print qq!$1<br>!;
	}
	print qq!<hr width=75% align=left>!;
	print qq!
		<br><br><br><br><br>
		<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
		<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		<INPUT TYPE="hidden" NAME="status" VALUE="DeleteProjectConfirmation">
		<p><b>Delete Project  </b><INPUT TYPE="submit" NAME="Submit" VALUE="Delete"></font>
		</FORM>\n<p>
	!;
	
	print qq!<hr width=75% align=left>!;
	print qq!
		<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
		<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		<INPUT TYPE="hidden" NAME="status" VALUE="ArchiveProject">
		<br><b>Archive project and results	</b><INPUT TYPE="submit" NAME="Submit" VALUE="Archive">
		</FORM>\n<p>
	!;
}

if ($status=~/^GetExperiment$/)   
{
	my $project_id=$query->param("project_id");
	my $file=$query->param("file"); 
	GetProjects(-1,-1);
	open(IN,qq!$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/$file-experiment.xml!);
	print qq!<pre>\n!; 
	while($line=<IN>)
	{ 
		$line=~s/\</\&lt;/g;
		$line=~s/\>/\&gt;/g;
		print qq!$line!; 
	}
	print qq!</pre>\n!; 
	close(IN);
}

if($status=~/DeleteAnalysisFile/)
{
	my $project_id=$query->param("project_id");
	GetProjects(-1,-1); 
	my $file_name=$query->param("filename"); 
	my $dir=$query->param("dir"); 
	$todo_dev="$SETTINGS{'TASKS'}\/$dir\/$file_name";
	$todo_dev=~s/\//\\/g;
	$todo_data="$SETTINGS{'DATA'}\/$PROJECT_PATH{$project_id}\/$dir\/$SETTINGS{'DEMON'}\/$file_name";
	$todo_data=~s/\//\\/g;
	if($dir eq "todo")
	{
		system(qq!del "$todo_dev" /Q!);
		system(qq!del "$todo_data" /Q!);
	}
	$running_dev="$SETTINGS{'TASKS'}/$dir/$SETTINGS{'DEMON'}/$file_name";
	$running_dev=~s/\//\\/g;
	$running_data="$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/$dir/$SETTINGS{'DEMON'}/$file_name";
	$running_data=~s/\//\\/g;
	if($dir eq "running")
	{
		system(qq!del "$running_dev" /Q!);
		system(qq!del "$running_data" /Q!);
	}
	print qq!<b>Analysis File $file_name has been deleted</b><br>\n!;
	print qq!<b>Continue : </b>!;
	print qq!
		<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
		<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		<INPUT TYPE="hidden" NAME="status" VALUE="ViewProject">
		<INPUT TYPE="submit" NAME="Submit" VALUE="Continue">
		</FORM>\n
	!;
}

if ($status=~/^DataAnalysisProgramList$/)
{
	my $project_id=$query->param("project_id");
	GetProjects($project_id,-1);
	my $res_dir=""; 
	$PROJECT_PATH_{$project_id}=$PROJECT_PATH{$project_id};
	while($PROJECT_PATH_{$project_id}=~s/^\/([^\/]+)//)
	{
		my $temp=$1;
		$res_dir.=$temp."/"; 
	} 
	my $dataanalysis_date=$query->param("dataanalysis_date");
	my $dataanalysis_name=$query->param("dataanalysis_name");
	my $job=$dataanalysis_date;
	$job=~s/^.*\-(20[0-9][0-9]-[0-9][0-9]-[0-9][0-9])/$1/;
	$job.="&nbsp;&nbsp;&nbsp;$dataanalysis_name";
	$job=~s/\-analysis$/\)/;
	$job=~s/__/ \(/;
	print qq!<b>$job</b><p>!;
	@step_list = GetDataAnalysisSteps($dataanalysis_date,$dataanalysis_name,$res_dir);
	print qq!
		<p>
		<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data">
		<INPUT TYPE="hidden" NAME="status" VALUE="DataAnalysisInputFiles">
		<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		</FORM>
	!;
	for(my $i=1;$i<=@step_list;$i++)
	{
		my $step_text=$step_list[$i-1];
		if($step_list[$i-1]!~/Cleanup.*/ and $step_list[$i-1]!~/Create.*/)
		{
			print qq!<a href="pipeline_cgi.pl?dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_num=$i&step_select=$step_list[$i-1]&status=DataAnalysisInputFiles&project_id=$project_id">$i.</a> $step_text<br>!;
		}
		else {	print qq!$i. $step_text<br>!;	}
	}
}
if ($status=~/^DataAnalysisInputFiles$/)
{
	my $project_id=$query->param("project_id");
	GetProjects($project_id,-1);
	my $res_dir=""; 
	$PROJECT_PATH_{$project_id}=$PROJECT_PATH{$project_id};
	while($PROJECT_PATH_{$project_id}=~s/^\/([^\/]+)//)
	{
		my $temp=$1;
		$res_dir.=$temp."/"; 
	}
	my $dataanalysis_date=$query->param("dataanalysis_date");
	my $dataanalysis_name=$query->param("dataanalysis_name");
	my $step_select=$query->param("step_select");
	my $step_num=$query->param("step_num");
	my $job=$dataanalysis_date;
	$job=~s/^.*\-(20[0-9][0-9]-[0-9][0-9]-[0-9][0-9])/$1/;
	$job.="&nbsp;&nbsp;&nbsp;$dataanalysis_name";
	$job=~s/\-analysis$/\)/;
	$job=~s/__/ \(/;
	print qq!<b>$job</b><br>$step_select<br><p>!;
	if($step_select=~/QC \(qc_mgf_exp\.pl.*/)
	{ 
		@data_files = GetDataAnalysisInputFiles($dataanalysis_date,$dataanalysis_name,$step_select,$step_num,$res_dir); 
		for(my $i=1;$i<=@data_files;$i++)
		{ 
			print qq!$i. $data_files[$i-1]!;
			{ 
				print qq! (<a href="pipeline_cgi.pl?choice=charge&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysisMgfResults&project_id=$project_id">charge</a>,!;  
				print qq! <a href="pipeline_cgi.pl?choice=mz&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysisMgfResults&project_id=$project_id">mz</a>)<br>!; 
			}
		}
	}
	if($step_select=~/QC \(qc_mzxml_exp\.pl.*/)
	{ 
		@data_files = GetDataAnalysisInputFiles($dataanalysis_date,$dataanalysis_name,$step_select,$step_num,$res_dir); 
		for(my $i=1;$i<=@data_files;$i++)
		{
			print qq!$i. $data_files[$i-1]!;
			{ 
				print qq! (<a href="pipeline_cgi.pl?choice=charge&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysismzXMLResults&project_id=$project_id">charge</a>,!;  
				print qq! <a href="pipeline_cgi.pl?choice=mz&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysismzXMLResults&project_id=$project_id">mz</a>,!;   
				print qq! <a href="pipeline_cgi.pl?choice=scan&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysismzXMLResults&project_id=$project_id">scan</a>)<br>!; 
			}
		}
	}
	##### xhunter display : begin #####
	if($step_select=~/ID \(xhunter\.pl.*/)
	{
		@data_files = GetDataAnalysisInputFiles($dataanalysis_date,$dataanalysis_name,$step_select,$step_num,$res_dir); 
		for(my $i=1;$i<=@data_files;$i++)
		{
			print qq!$i. $data_files[$i-1]!; 
			print qq! <a href="http://$SETTINGS{'XHUNTER'}/thegpm-cgi/plist.pl?npep=0&path=$SETTINGS{'RESULT'}/$res_dir$dataanalysis_date/$data_files[$i-1]&proex=-1&ltype=2">XHunter<br></a>!;
		}
	}
	##### xhunter display : end ##### 
	if($step_select=~/ID \(xtandem\.pl.*/)
	{
		@data_files = GetDataAnalysisInputFiles($dataanalysis_date,$dataanalysis_name,$step_select,$step_num,$res_dir); 
		for(my $i=1;$i<=@data_files;$i++)
		{
			print qq!$i. $data_files[$i-1]!; 
			print qq! <a href="http://$SETTINGS{'XTANDEM'}/thegpm-cgi/plist.pl?npep=0&path=$SETTINGS{'RESULT'}/$res_dir$dataanalysis_date/$data_files[$i-1]&proex=-1&ltype=2">XTandem<br></a>!;
		}
	}	
	if($step_select=~/ID \(xtandem_prepare_only\.pl.*/)
	{
		@data_files = GetDataAnalysisInputFiles($dataanalysis_date,$dataanalysis_name,$step_select,$step_num,$res_dir); 
		for(my $i=1;$i<=@data_files;$i++)
		{
			print qq!$i. $data_files[$i-1]!; 
			print qq! <a href="http://$SETTINGS{'XTANDEM'}/thegpm-cgi/plist.pl?npep=0&path=$SETTINGS{'RESULT'}/$res_dir$dataanalysis_date/$data_files[$i-1]&proex=-1&ltype=2">XTandem<br></a>!;
		}
	}
	if($step_select=~/ID \(mass\_calibration\_exp\.pl.*/)
	{
		@data_files = GetDataAnalysisInputFiles($dataanalysis_date,$dataanalysis_name,$step_select,$step_num,$res_dir);
		@calibrate_level=("MS1","MS2");
		for(my $i=1;$i<=@data_files;$i++)
		{
			$data_file=$data_files[$i-1];
			$data_file=~s/\_cal.MGF$//i;
			$data_files[$i-1]=$data_file;
			print qq!$i. $data_files[$i-1]<br>\n!; 
			foreach my $value(@calibrate_level)
			{ 
				print qq!<b>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;$value</b><br>\n!;
				print qq!&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;Da : <a href="pipeline_cgi.pl?level=$value&choice=da-distr&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysisQCResults&project_id=$project_id">$value:da-distr</a>,!;  
				print qq! <a href="pipeline_cgi.pl?level=$value&choice=da-m&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysisQCResults&project_id=$project_id">$value:da-m</a>,!;  
				print qq! <a href="pipeline_cgi.pl?level=$value&choice=damz&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysisQCResults&project_id=$project_id">$value:da-mz</a>,!;  
				print qq! <a href="pipeline_cgi.pl?level=$value&choice=da-rt&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysisQCResults&project_id=$project_id">$value:da-rt</a>!;  
				print qq!<br>\n&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;PPM : <a href="pipeline_cgi.pl?level=$value&choice=ppm-distr&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysisQCResults&project_id=$project_id">$value:ppm-distr</a>,!;  
				print qq! <a href="pipeline_cgi.pl?level=$value&choice=ppm-m&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysisQCResults&project_id=$project_id">$value:ppm-m</a>,!;  
				print qq! <a href="pipeline_cgi.pl?level=$value&choice=ppmmz&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysisQCResults&project_id=$project_id">$value:ppm-mz</a>,!;  
				print qq! <a href="pipeline_cgi.pl?level=$value&choice=ppm-rt&dataanalysis_date=$dataanalysis_date&dataanalysis_name=$dataanalysis_name&step_select=$step_select&data_files=$data_files[$i-1]&status=DataAnalysisQCResults&project_id=$project_id">$value:ppm-rt</a> !; 
				print qq!<br>\n!;
			}
			print qq!<br>\n!;
		}
	}
}
if ($status=~/^DataAnalysisQCResults$/)
{
	my $project_id=$query->param("project_id");
	GetProjects($project_id,-1);
	# my $root_name=$SETTINGS{'RESULT'};
	# $root_name=~s/.*\/([^\/]+)$/$1/; 
	# my $res_dir=$root_name."\/"; 
	my $res_dir=""; 
	$PROJECT_PATH_{$project_id}=$PROJECT_PATH{$project_id};
	while($PROJECT_PATH_{$project_id}=~s/^\/([^\/]+)//)
	{
		my $temp=$1;
		$res_dir.=$temp."/"; 
	}
	my $dataanalysis_date=$query->param("dataanalysis_date");
	my $dataanalysis_name=$query->param("dataanalysis_name");
	my $step_select=$query->param("step_select");
	my $data_files=$query->param("data_files");
	my $choice=$query->param("choice");
	my $level=$query->param("level");
	my $job=$dataanalysis_date;
	$job=~s/^.*\-(20[0-9][0-9]-[0-9][0-9]-[0-9][0-9])/$1/;
	$job.="&nbsp;&nbsp;&nbsp;$dataanalysis_name";
	$job=~s/\-analysis$/\)/;
	$job=~s/__/ \(/;
	print qq!<b>$job</b><br>$step_select<br>$data_files: $level-$choice<br><p>!;

	if($choice=~/da-distr/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/id/before_cal/$level-da-distr-$data_files.png"><br>!;
	}
	if($choice=~/da-m/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/id/before_cal/$level-da-m-$data_files.png"><br>!;
	}
	if($choice=~/damz/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/id/before_cal/$level-da-mz-$data_files.png"><br>!;
	}
	if($choice=~/da-rt/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/id/before_cal/$level-da-rt-$data_files.png"><br>!;
	}
	if($choice=~/ppm-distr/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/id/before_cal/$level-ppm-distr-$data_files.png"><br>!;
	}
	if($choice=~/ppm-m/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/id/before_cal/$level-ppm-m-$data_files.png"><br>!;
	}
	if($choice=~/ppmmz/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/id/before_cal/$level-ppm-mz-$data_files.png"><br>!;
	}
	if($choice=~/ppm-rt/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/id/before_cal/$level-ppm-rt-$data_files.png"><br>!;
	}
}
if ($status=~/^DataAnalysisMgfResults$/)
{
	my $project_id=$query->param("project_id");
	GetProjects($project_id,-1);
	# my $root_name=$SETTINGS{'RESULT'};
	# $root_name=~s/.*\/([^\/]+)$/$1/; 
	# my $res_dir=$root_name."\/"; 
	my $res_dir=""; 
	$PROJECT_PATH_{$project_id}=$PROJECT_PATH{$project_id};
	while($PROJECT_PATH_{$project_id}=~s/^\/([^\/]+)//)
	{
		my $temp=$1;
		$res_dir.=$temp."/"; 
	}
	my $dataanalysis_date=$query->param("dataanalysis_date");
	my $dataanalysis_name=$query->param("dataanalysis_name");
	my $step_select=$query->param("step_select");
	my $data_files=$query->param("data_files");
	my $choice=$query->param("choice"); 
	my $job=$dataanalysis_date;
	$job=~s/^.*\-(20[0-9][0-9]-[0-9][0-9]-[0-9][0-9])/$1/;
	$job.="&nbsp;&nbsp;&nbsp;$dataanalysis_name";
	$job=~s/\-analysis$/\)/;
	$job=~s/__/ \(/;
	print qq!<b>$job</b><br>$step_select<br>$data_files: $choice<br><p>!;
	if($choice=~/charge/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/data/mgf_charge/$data_files.charge.png"><br>!;
	}
	if($choice=~/mz/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/data/mgf_mz/$data_files.mass.png"><br>!;
	}
}
if ($status=~/^DataAnalysismzXMLResults$/)
{
	my $project_id=$query->param("project_id");
	GetProjects($project_id,-1);
	# my $root_name=$SETTINGS{'RESULT'};
	# $root_name=~s/.*\/([^\/]+)$/$1/; 
	# my $res_dir=$root_name."\/"; 
	my $res_dir=""; 
	$PROJECT_PATH_{$project_id}=$PROJECT_PATH{$project_id};
	while($PROJECT_PATH_{$project_id}=~s/^\/([^\/]+)//)
	{
		my $temp=$1;
		$res_dir.=$temp."/"; 
	}
	my $dataanalysis_date=$query->param("dataanalysis_date");
	my $dataanalysis_name=$query->param("dataanalysis_name");
	my $step_select=$query->param("step_select");
	my $data_files=$query->param("data_files");
	my $choice=$query->param("choice");
	print qq!<p><b>$dataanalysis_date: $dataanalysis_name.xml<br>$step_select<br>$data_files: $choice<br></b><p>!;
	if($choice=~/charge/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/data/mzxml_charge/$data_files.charge.png"><br>!;
	}
	if($choice=~/mz/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/data/mzxml_mz/$data_files.mz.png"><br>!;
	}
	if($choice=~/scan/)
	{
		print qq!<img src="/pipeline/$res_dir/$dataanalysis_date/plots/data/mzxml_scan/$data_files.scan.png"><br>!;
	}
}
