#!c:/perl/bin/perl.exe
require "pipeline_cgi_projexp.pl";
require "pipeline_cgi_results.pl";
require "pipeline_cgi.pl";

use CGI;
use LWP::Simple;

my $ip = $ENV{'REMOTE_ADDR'};
my $status=$query->param("status");
my $project_id=$query->param("project_id");	
if ($project_id!~/\w/) { $project_id=-1; }
my $message=""; 
my $sampleprotfilename=""; 
my $samplepepfilename="";
my %protein_exp_list=();
my %unique_pep_count_sample=();
my %total_pep_count_sample=();
my %peptide_hash=();
my %protein_hash=();
my %related_proteins=();
my %done_proteins=();
my %protein_description=();
my %protein_filename=();
my $sample_count=0;
my $datetime = GetDateTime();

if ($status=~/^CreateReportStep1$/)   
{
	my $project_id=$query->param("project_id");
	print qq!<b>Create Reports (Step 1)</b><br>!;
	%DATA_ANALYSIS_LIST=();
	GetDataAnalysisList($project_id,"$SETTINGS{'DATA'}/$PROJECT_PATH{$project_id}/done");
	my $done=$DATA_ANALYSIS_LIST{$project_id};
	print qq!
			<FORM ACTION="pipeline_cgi_reports.pl" METHOD="post" ENCTYPE="multipart/form-data">
			<INPUT TYPE="hidden" NAME="status" VALUE="CreateReportStep2">
			<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
	!;
	print qq!Sample Exclude<br>!;
	while($done=~s/^#([^#]+)#//)
	{
		$filename=$1; 
		if ($filename=~/^(.*)\.xml\-(.*)$/i)
		{
			$xml_name=$1;
			$name_date=$2;
			$name=$xml_name;
			$name=~s/\-analysis$//;
			$name=~s/^(.*)__(.*)$/$1 ($2)/;
			print qq!
				<INPUT TYPE="hidden" NAME="name" VALUE="$name">
				<INPUT TYPE="radio" NAME="$name" VALUE="$name#sample">&nbsp;&nbsp;&nbsp;&nbsp;
				<INPUT TYPE="radio" NAME="$name" VALUE="$name#exclude" checked>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
				$name<br>
			!;
		}
	}
	print qq!<br>!;
	print qq!
		<INPUT TYPE="Submit" NAME="submit" VALUE="Next">
		</FORM>
	!;
}

if ($status=~/^CreateReportStep2$/)   
{
	my $project_id=$query->param("project_id");	
	print qq!<b>Create Reports (Step 2)</b><br>!;
	my @array = $query->param('name');	
	my $dir = "$SETTINGS{'RESULT'}/$PROJECT_PATH{$project_id}";
	if (opendir(dir,"$dir"))
	{
		%subdirectories=readdir dir;
		closedir dir;
	}
	print qq!
			<FORM ACTION="pipeline_cgi_reports.pl" METHOD="post" ENCTYPE="multipart/form-data">
			<INPUT TYPE="hidden" NAME="status" VALUE="CreateReportStepForm">
			<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
	!;
	print qq!S1&nbsp;&nbsp;S2&nbsp;&nbsp;S3&nbsp;&nbsp;S4&nbsp;&nbsp;S5&nbsp;&nbsp;S6&nbsp;&nbsp;S7&nbsp;&nbsp;S8&nbsp;&nbsp;S9&nbsp;&nbsp;S10&nbsp;&nbsp;Exclude<br>!;
	foreach my $choice(@array) 
	{ 
		$option=$query->param($choice); 
		if($option=~/([^#]+)#([^#]+)/) { $select=$2; $value=$1; } 
		$value=~s/\s\((.*)\)//;
		foreach my $value_(%subdirectories) 
		{
			if($value_=~/^$value\-.*/ and $value_!~/.tgz$/ and $value_!~/.rar$/) 
			{ 
				my $res_dir=$dir."\/".$value_; 
				if (opendir(dir,"$res_dir"))
				{
					@allfiles=readdir dir;
					closedir dir;
				}
				foreach my $xmlfile(@allfiles)
				{
					if($xmlfile=~/.*\.xml$/ and $xmlfile!~/input\_.*/)
					{
						print qq!<INPUT TYPE="hidden" NAME="location" VALUE="$res_dir\#$xmlfile">&nbsp;&nbsp;&nbsp;&nbsp;!;
						if($select=~/sample/)
						{
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="1" checked>&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="2">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="3">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="4">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="5">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="6">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="7">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="8">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="9">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="10">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="exclude" >&nbsp;&nbsp;!;
						}
						if($select=~/exclude/)
						{
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="1">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="2">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="3">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="4">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="5">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="6">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="7">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="8">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="9">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="10">&nbsp;&nbsp;!;
							print qq!<INPUT TYPE="radio" NAME="$res_dir\#$xmlfile" VALUE="exclude" checked>&nbsp;&nbsp;!;
						}
						print qq!$xmlfile&nbsp;&nbsp;($value)<br>!;
					}
				}
			}
		}
	}
	print qq!<br><br>
	<b>Protein expectation value cutoff &nbsp;</b><INPUT TYPE="text" NAME="prot_cutoff" VALUE="-5"><br><br>
	<b>Peptide expectation value cutoff &nbsp;</b><INPUT TYPE="text" NAME="pep_cutoff" VALUE="-5"><br><br>
	<INPUT TYPE="submit" NAME="submit" VALUE="Next"><br>
	</FORM>
	!;
}
if($status=~/^CreateReportStepForm$/)
{	
	my $project_id=$query->param("project_id");
	my $prot_cutoff=$query->param("prot_cutoff");
	my $pep_cutoff=$query->param("pep_cutoff");
	my @location=$query->param("location");
	my %sample=();  
	my $i1=1; 
	my $i2=1; 
	my $i3=1; 
	my $i4=1; 
	my $i5=1; 
	my $i6=1; 
	my $i7=1; 
	my $i8=1; 
	my $i9=1; 
	my $i10=1;
	foreach my $value(@location)
	{
		my $choice=$query->param($value); 
		$value=~s/\#/\//; 
		if($choice eq "1")	{	$sample{$choice}.="#$value#";  }
		if($choice eq "2")	{	$sample{$choice}.="#$value#";  }
		if($choice eq "3")	{	$sample{$choice}.="#$value#";  }
		if($choice eq "4")	{	$sample{$choice}.="#$value#";  }
		if($choice eq "5")	{	$sample{$choice}.="#$value#";  }
		if($choice eq "6")	{	$sample{$choice}.="#$value#";  }
		if($choice eq "7")	{	$sample{$choice}.="#$value#";  }
		if($choice eq "8")	{	$sample{$choice}.="#$value#";  }
		if($choice eq "9")	{	$sample{$choice}.="#$value#";  }
		if($choice eq "10")	{	$sample{$choice}.="#$value#"; }
	}
	creatReport($prot_cutoff,$pep_cutoff,\%sample); 
}
sub creatReport
{	
	my $prot_cutoff=$_[0];
	my $pep_cutoff=$_[1];
	my $sample=$_[2];
	%samples = %$sample; 
	my %min_prot_exp_sample=();
	my %min_pep_exp_sample=();
	my %prot__sample=();
	my %peptides_sample=();
	my %protein_list=();
	$sample_count=keys %samples; 
	my $counter=0;
	
	if(%samples)
	{
		if($prot_cutoff=~/\w/ and $pep_cutoff=~/\w/)
		{	
			foreach my $key(sort keys %samples)
			{
				$counter++;
				$sample_="sample"."$counter";
				$temp=$samples{$key};
				while($temp=~s/#([^#]+)#//)
				{ 
					$value=$1;
					$xmlfile=$value; 
					open(IN,qq!$xmlfile!); 
					while($line=<IN>)
					{
						if($line=~/<protein expect="([\-0-9\.0-9]+)" .*label="([^\"]+)" .*sumI="([0-9\.0-9]+)" /)
						{
							$exp_prot=$1; 
							$prot_label=$2; 
							if($prot_label=~/([^\s]+)/) {  $prot_name=$1; } 
							if($prot__sample{"$prot_name#$sample_"}!~/\w/) { $min_prot_exp_sample{"$prot_name#$sample_"}=100000; }
							if($exp_prot<$min_prot_exp_sample{"$prot_name#$sample_"}) { $min_prot_exp_sample{"$prot_name#$sample_"}=$exp_prot; $prot__sample{"$prot_name#$sample_"}=$exp_prot; }
						}
						if($line=~/<domain id.*expect="([0-9\.\-\+edED]+)" mh="([^\"]+)" delta="([^\"]+)".*seq="([A-Za-z]+)".*>/) 
						{
							$exp_pep=log($1)/log(10); 
							$pep=$4;
							$pep=~tr/L/I/; 
							if($pep{"$prot_name#$pep#$sample_"}!~/\w/) { $min_pep_exp_sample{"$prot_name#$pep#$sample_"}=100000; }
							if($exp_pep<$min_pep_exp_sample{"$prot_name#$pep#$sample_"}) { $min_pep_exp_sample{"$prot_name#$pep#$sample_"}=$exp_pep; $pep{"$prot_name#$pep#$sample_"}=$exp_pep; }
						}
						elsif($line=~/<aa type="([a-zA-Z]+)" at="([0-9]+)" modified="([\-0-9\.0-9]+)" \/>/)
						{
							$aa=$1;
							$at=$2;
							$mod=$3;
							$mod_string="$mod\@$aa$at";
							if($modification{$pep}!~m/$mod_string/) { $modification{$pep}.="$mod_string,"; }
						}
					}
					close(IN);
				}
			}
			$counter=0;
			$sample_="";
			foreach my $key(sort keys %samples)
			{
				$counter++;
				$sample_="sample"."$counter";  
				$sampleprotfilename="sampleprot"."$counter"."-".$ip."-".$datetime; 
				$sampleprotfilename=~s/([\s\:\.]+)/\-/g;
				$sample_="sample"."$counter";  
				$samplepepfilename="samplepep"."$counter"."-".$ip."-".$datetime; 
				$samplepepfilename=~s/([\s\:\.]+)/\-/g;	
				$samplefilename="sample"."$counter"."-".$ip."-".$datetime; 
				$samplefilename=~s/([\s\:\.]+)/\-/g;
				open(OUT,qq!>$sampleprotfilename!);
				open(OUT1,qq!>$samplepepfilename!);
				open(OUT2,qq!>$samplefilename!);
				$temp=$samples{$key};
				while($temp=~s/#([^#]+)#//)
				{ 
					$value=$1; 
					$xmlfile=$value; 
					print OUT2 qq!$xmlfile\n!;
					open(IN,qq!$xmlfile!); 
					while($line=<IN>)
					{
						if($line=~/<group.*label="([^\s]+)" type="([^\"]+)" sumI="([^\"]+)".*>/)
						{
							#$prot_name=$1;
							$group_type=$2;
							$group_sumI=$3;
						}
						elsif($line=~/<protein expect="([\-0-9\.0-9]+)" .*label="([^\"]+)" .*sumI="([0-9\.0-9]+)" /)
						{
							$exp_prot=$1; 
							$prot_label=$2;
							$sumI=$3; 
							if($prot_label=~/([^\s]+)/) {  $prot_name=$1; }
						}
						elsif($line=~/<note label="description">(.*)<\/note>/)
						{
							$protein_description{$prot_name}="$1";
						}
						elsif($line=~/<domain id.*expect="([0-9\.\-\+edED]+)" mh="([^\"]+)" delta="([^\"]+)".*seq="([A-Za-z]+)".*>/) 
						{
							$exp_pep=log($1)/log(10); 
							$mh=$2;
							$delta=$3;
							$pep=$4;
							$pep=~tr/L/I/; 
						}
						elsif($line=~/<\/domain>/)
						{
							if (!$modification{$pep}) { $modification{$pep}="none"; }
							if($exp_pep<=$pep_cutoff and $exp_prot<=$prot_cutoff)
							{	
								if($unique_pep_count_sample{"$prot_name#$sample_"}!~/\w/) { $unique_pep_count_sample{"$prot_name#$sample_"}=0;}
								if($total_pep_count_sample{"$prot_name#$sample_"}!~/\w/) { $total_pep_count_sample{"$prot_name#$sample_"}=0; }
								$value="&$sample_&&$pep&&$modification{$pep}&";  
								if($pep_exp_sample{$prot_name}{$exp_pep}!~m/$value/ and $exp_pep==$min_pep_exp_sample{"$prot_name#$pep#$sample_"})
								{  
									if($prot_sample{$prot_name}!~/\w/ and $exp_prot==$min_prot_exp_sample{"$prot_name#$sample_"}) 
									{	
										$prot_sample{$prot_name}="$exp_prot#$sumI"; 
									}  	
									$protein_filename{"$prot_name#$sample_"}="$exp_prot#$sumI"; 
									$pep_exp_sample{$prot_name}{$exp_pep}.="#&$sample_&&$pep&&$modification{$pep}&&$exp_pep&&$sumI&&$mh&&$delta&#"; 
									print OUT qq!$prot_name\t$protein_filename{"$prot_name#$sample_"}\n!;
									print OUT1 qq!$prot_name\t$pep\t$pep_exp_sample{$prot_name}{$exp_pep}\n!;
								}
								if($peptides_sample{"$prot_name#$pep#$sample_"}!~/\w/) { $peptides_sample{"$prot_name#$pep#$sample_"}="$pep"; $unique_pep_count_sample{"$prot_name#$sample_"}++; }
								$total_pep_count_sample{"$prot_name#$sample_"}++; 
							} 
						}
						elsif($line=~/<\/group>/)
						{  
							$pep="";
							$exp_pep="";
							$mh="";
							$delta="";
							$pre="";
							$post="";
							$exp_prot=""; 
							$prot_name="";
							$group_type="";
							$group_sumI="";
							$sumI="";
						}
					}
					close(IN);
				}
				close(OUT);
				close(OUT1);
				close(OUT2);
			}
		}
		elsif($prot_cutoff=~/\w/ and $pep_cutoff!~/\w/)
		{	
			foreach my $key(sort keys %samples)
			{
				$counter++;
				$sample_="sample"."$counter"; 
				$temp=$samples{$key};
				while($temp=~s/#([^#]+)#//)
				{ 
					$value=$1; 
					$xmlfile=$value;
					open(IN,qq!$xmlfile!); 
					while($line=<IN>)
					{
						if($line=~/<protein expect="([\-0-9\.0-9]+)" .*label="([^\"]+)" .*sumI="([0-9\.0-9]+)" /)
						{
							$exp_prot=$1; 
							$prot_label=$2; 
							if($prot_label=~/([^\s]+)/) {  $prot_name=$1; } 
							if($prot__sample{"$prot_name#$sample_"}!~/\w/) { $min_prot_exp_sample{"$prot_name#$sample_"}=100000; }
							if($exp_prot<$min_prot_exp_sample{"$prot_name#$sample_"}) { $min_prot_exp_sample{"$prot_name#$sample_"}=$exp_prot; $prot__sample{"$prot_name#$sample_"}=$exp_prot; }
						}
						if($line=~/<domain id.*expect="([0-9\.\-\+edED]+)" mh="([^\"]+)" delta="([^\"]+)".*seq="([A-Za-z]+)".*>/) 
						{
							$exp_pep=log($1)/log(10); 
							$pep=$4;
							$pep=~tr/L/I/; 
							if($pep{"$prot_name#$pep#$sample_"}!~/\w/) { $min_pep_exp_sample{"$prot_name#$pep#$sample_"}=100000; }
							if($exp_pep<$min_pep_exp_sample{"$prot_name#$pep#$sample_"}) { $min_pep_exp_sample{"$prot_name#$pep#$sample_"}=$exp_pep; $pep{"$prot_name#$pep#$sample_"}=$exp_pep; }
						}
						elsif($line=~/<aa type="([a-zA-Z]+)" at="([0-9]+)" modified="([\-0-9\.0-9]+)" \/>/)
						{
							$aa=$1;
							$at=$2;
							$mod=$3;
							$mod_string="$mod\@$aa$at";
							if($modification{$pep}!~m/$mod_string/) { $modification{$pep}.="$mod_string,"; }
						}
					}
					close(IN);
				}
			}
			$counter=0;
			$sample_="";
			foreach my $key(sort keys %samples)
			{
				$counter++;
				$sample_="sample"."$counter";  
				$sampleprotfilename="sampleprot"."$counter"."-".$ip."-".$datetime; 
				$sampleprotfilename=~s/([\s\:\.]+)/\-/g;
				$sample_="sample"."$counter";  
				$samplepepfilename="samplepep"."$counter"."-".$ip."-".$datetime; 
				$samplepepfilename=~s/([\s\:\.]+)/\-/g;	
				$samplefilename="sample"."$counter"."-".$ip."-".$datetime; 
				$samplefilename=~s/([\s\:\.]+)/\-/g;
				open(OUT,qq!>$sampleprotfilename!);
				open(OUT1,qq!>$samplepepfilename!);
				open(OUT2,qq!>$samplefilename!);
				$temp=$samples{$key};
				while($temp=~s/#([^#]+)#//)
				{ 
					$value=$1; 
					$xmlfile=$value;
					print OUT2 qq!$xmlfile\n!;				
					open(IN,qq!$xmlfile!); 
					while($line=<IN>)
					{
						if($line=~/<group.*label="([^\s]+)" type="([^\"]+)" sumI="([^\"]+)".*>/)
						{
							#$prot_name=$1;
							$group_type=$2;
							$group_sumI=$3;
						}
						elsif($line=~/<protein expect="([\-0-9\.0-9]+)" .*label="([^\"]+)" .*sumI="([0-9\.0-9]+)" /)
						{
							$exp_prot=$1; 
							$prot_label=$2;
							$sumI=$3; 
							if($prot_label=~/([^\s]+)/) {  $prot_name=$1; }
						}
						elsif($line=~/<note label="description">(.*)<\/note>/)
						{
							$protein_description{$prot_name}="$1";
						}
						elsif($line=~/<domain id.*expect="([0-9\.\-\+edED]+)" mh="([^\"]+)" delta="([^\"]+)".*seq="([A-Za-z]+)".*>/) 
						{
							$exp_pep=log($1)/log(10); 
							$mh=$2;
							$delta=$3;
							$pep=$4;
							$pep=~tr/L/I/; 
						}
						elsif($line=~/<\/domain>/)
						{
							if (!$modification{$pep}) { $modification{$pep}="none"; }
							if($exp_prot<=$prot_cutoff)
							{	
								if($unique_pep_count_sample{"$prot_name#$sample_"}!~/\w/) { $unique_pep_count_sample{"$prot_name#$sample_"}=0;}
								if($total_pep_count_sample{"$prot_name#$sample_"}!~/\w/) { $total_pep_count_sample{"$prot_name#$sample_"}=0; }
								$value="&$sample_&&$pep&&$modification{$pep}&";  
								if($pep_exp_sample{$prot_name}{$exp_pep}!~m/$value/ and $exp_pep==$min_pep_exp_sample{"$prot_name#$pep#$sample_"})
								{  
									if($prot_sample{$prot_name}!~/\w/ and $exp_prot==$min_prot_exp_sample{"$prot_name#$sample_"}) 
									{	
										$prot_sample{$prot_name}="$exp_prot#$sumI"; 
									}  	
									$protein_filename{"$prot_name#$sample_"}="$exp_prot#$sumI"; 
									$pep_exp_sample{$prot_name}{$exp_pep}.="#&$sample_&&$pep&&$modification{$pep}&&$exp_pep&&$sumI&&$mh&&$delta&#"; 
									print OUT qq!$prot_name\t$protein_filename{"$prot_name#$sample_"}\n!;
									print OUT1 qq!$prot_name\t$pep\t$pep_exp_sample{$prot_name}{$exp_pep}\n!;
								}
								if($peptides_sample{"$prot_name#$pep#$sample_"}!~/\w/) { $peptides_sample{"$prot_name#$pep#$sample_"}="$pep"; $unique_pep_count_sample{"$prot_name#$sample_"}++; }
								$total_pep_count_sample{"$prot_name#$sample_"}++; 
							} 
						}
						elsif($line=~/<\/group>/)
						{  
							$pep="";
							$exp_pep="";
							$mh="";
							$delta="";
							$pre="";
							$post="";
							$exp_prot=""; 
							$prot_name="";
							$group_type="";
							$group_sumI="";
							$sumI="";
						}
					}
					close(IN);
				}
				close(OUT);
				close(OUT1);
				close(OUT2);
			}
		}
		elsif($prot_cutoff!~/\w/ and $pep_cutoff=~/\w/)
		{	
			foreach my $key(sort keys %samples)
			{
				$counter++;
				$sample_="sample"."$counter"; 
				$temp=$samples{$key};
				while($temp=~s/#([^#]+)#//)
				{ 
					$value=$1; 
					$xmlfile=$value;
					open(IN,qq!$xmlfile!); 
					while($line=<IN>)
					{
						if($line=~/<protein expect="([\-0-9\.0-9]+)" .*label="([^\"]+)" .*sumI="([0-9\.0-9]+)" /)
						{
							$exp_prot=$1; 
							$prot_label=$2; 
							if($prot_label=~/([^\s]+)/) {  $prot_name=$1; } 
							if($prot__sample{"$prot_name#$sample_"}!~/\w/) { $min_prot_exp_sample{"$prot_name#$sample_"}=100000; }
							if($exp_prot<$min_prot_exp_sample{"$prot_name#$sample_"}) { $min_prot_exp_sample{"$prot_name#$sample_"}=$exp_prot; $prot__sample{"$prot_name#$sample_"}=$exp_prot; }
						}
						if($line=~/<domain id.*expect="([0-9\.\-\+edED]+)" mh="([^\"]+)" delta="([^\"]+)".*seq="([A-Za-z]+)".*>/) 
						{
							$exp_pep=log($1)/log(10); 
							$pep=$4;
							$pep=~tr/L/I/; 
							if($pep{"$prot_name#$pep#$sample_"}!~/\w/) { $min_pep_exp_sample{"$prot_name#$pep#$sample_"}=100000; }
							if($exp_pep<$min_pep_exp_sample{"$prot_name#$pep#$sample_"}) { $min_pep_exp_sample{"$prot_name#$pep#$sample_"}=$exp_pep; $pep{"$prot_name#$pep#$sample_"}=$exp_pep; }
						}
						elsif($line=~/<aa type="([a-zA-Z]+)" at="([0-9]+)" modified="([\-0-9\.0-9]+)" \/>/)
						{
							$aa=$1;
							$at=$2;
							$mod=$3;
							$mod_string="$mod\@$aa$at";
							if($modification{$pep}!~m/$mod_string/) { $modification{$pep}.="$mod_string,"; }
						}
					}
					close(IN);
				}
			}
			$counter=0;
			$sample_="";
			foreach my $key(sort keys %samples)
			{
				$counter++;
				$sample_="sample"."$counter";  
				$sampleprotfilename="sampleprot"."$counter"."-".$ip."-".$datetime; 
				$sampleprotfilename=~s/([\s\:\.]+)/\-/g;
				$sample_="sample"."$counter";  
				$samplepepfilename="samplepep"."$counter"."-".$ip."-".$datetime; 
				$samplepepfilename=~s/([\s\:\.]+)/\-/g;	
				$samplefilename="sample"."$counter"."-".$ip."-".$datetime; 
				$samplefilename=~s/([\s\:\.]+)/\-/g;
				open(OUT,qq!>$sampleprotfilename!);
				open(OUT1,qq!>$samplepepfilename!); 
				open(OUT2,qq!>$samplefilename!); 
				$temp=$samples{$key};
				while($temp=~s/#([^#]+)#//)
				{ 
					$value=$1; 
					$xmlfile=$value;
					print OUT2 qq!$xmlfile\n!;
					open(IN,qq!$xmlfile!); 
					while($line=<IN>)
					{
						if($line=~/<group.*label="([^\s]+)" type="([^\"]+)" sumI="([^\"]+)".*>/)
						{
							#$prot_name=$1;
							$group_type=$2;
							$group_sumI=$3;
						}
						elsif($line=~/<protein expect="([\-0-9\.0-9]+)" .*label="([^\"]+)" .*sumI="([0-9\.0-9]+)" /)
						{
							$exp_prot=$1; 
							$prot_label=$2;
							$sumI=$3; 
							if($prot_label=~/([^\s]+)/) {  $prot_name=$1; }
						}
						elsif($line=~/<note label="description">(.*)<\/note>/)
						{
							$protein_description{$prot_name}="$1";
						}
						elsif($line=~/<domain id.*expect="([0-9\.\-\+edED]+)" mh="([^\"]+)" delta="([^\"]+)".*seq="([A-Za-z]+)".*>/) 
						{
							$exp_pep=log($1)/log(10); 
							$mh=$2;
							$delta=$3;
							$pep=$4;
							$pep=~tr/L/I/; 
						}
						elsif($line=~/<\/domain>/)
						{
							if (!$modification{$pep}) { $modification{$pep}="none"; }
							if($exp_pep<=$pep_cutoff)
							{	
								if($unique_pep_count_sample{"$prot_name#$sample_"}!~/\w/) { $unique_pep_count_sample{"$prot_name#$sample_"}=0;}
								if($total_pep_count_sample{"$prot_name#$sample_"}!~/\w/) { $total_pep_count_sample{"$prot_name#$sample_"}=0; }
								$value="&$sample_&&$pep&&$modification{$pep}&";  
								if($pep_exp_sample{$prot_name}{$exp_pep}!~m/$value/ and $exp_pep==$min_pep_exp_sample{"$prot_name#$pep#$sample_"})
								{  
									if($prot_sample{$prot_name}!~/\w/ and $exp_prot==$min_prot_exp_sample{"$prot_name#$sample_"}) 
									{	
										$prot_sample{$prot_name}="$exp_prot#$sumI"; 
									}  	
									$protein_filename{"$prot_name#$sample_"}="$exp_prot#$sumI"; 
									$pep_exp_sample{$prot_name}{$exp_pep}.="#&$sample_&&$pep&&$modification{$pep}&&$exp_pep&&$sumI&&$mh&&$delta&#"; 
									print OUT qq!$prot_name\t$protein_filename{"$prot_name#$sample_"}\n!;
									print OUT1 qq!$prot_name\t$pep\t$pep_exp_sample{$prot_name}{$exp_pep}\n!;
								}
								if($peptides_sample{"$prot_name#$pep#$sample_"}!~/\w/) { $peptides_sample{"$prot_name#$pep#$sample_"}="$pep"; $unique_pep_count_sample{"$prot_name#$sample_"}++; }
								$total_pep_count_sample{"$prot_name#$sample_"}++; 
							} 
						}
						elsif($line=~/<\/group>/)
						{  
							$pep="";
							$exp_pep="";
							$mh="";
							$delta="";
							$pre="";
							$post="";
							$exp_prot=""; 
							$prot_name="";
							$group_type="";
							$group_sumI="";
							$sumI="";
						}
					}
					close(IN);
				}
				close(OUT);
				close(OUT1);
				close(OUT2);
			}
		}
		else
		{	
			foreach my $key(sort keys %samples)
			{
				$counter++;
				$sample_="sample"."$counter"; 
				$temp=$samples{$key};
				while($temp=~s/#([^#]+)#//)
				{ 
					$value=$1; 
					$xmlfile=$value;
					open(IN,qq!$xmlfile!); 
					while($line=<IN>)
					{
						if($line=~/<protein expect="([\-0-9\.0-9]+)" .*label="([^\"]+)" .*sumI="([0-9\.0-9]+)" /)
						{
							$exp_prot=$1; 
							$prot_label=$2; 
							if($prot_label=~/([^\s]+)/) {  $prot_name=$1; } 
							if($prot__sample{"$prot_name#$sample_"}!~/\w/) { $min_prot_exp_sample{"$prot_name#$sample_"}=100000; }
							if($exp_prot<$min_prot_exp_sample{"$prot_name#$sample_"}) { $min_prot_exp_sample{"$prot_name#$sample_"}=$exp_prot; $prot__sample{"$prot_name#$sample_"}=$exp_prot; }
						}
						if($line=~/<domain id.*expect="([0-9\.\-\+edED]+)" mh="([^\"]+)" delta="([^\"]+)".*seq="([A-Za-z]+)".*>/) 
						{
							$exp_pep=log($1)/log(10); 
							$pep=$4;
							$pep=~tr/L/I/; 
							if($pep{"$prot_name#$pep#$sample_"}!~/\w/) { $min_pep_exp_sample{"$prot_name#$pep#$sample_"}=100000; }
							if($exp_pep<$min_pep_exp_sample{"$prot_name#$pep#$sample_"}) { $min_pep_exp_sample{"$prot_name#$pep#$sample_"}=$exp_pep; $pep{"$prot_name#$pep#$sample_"}=$exp_pep; }
						}
						elsif($line=~/<aa type="([a-zA-Z]+)" at="([0-9]+)" modified="([\-0-9\.0-9]+)" \/>/)
						{
							$aa=$1;
							$at=$2;
							$mod=$3;
							$mod_string="$mod\@$aa$at";
							if($modification{$pep}!~m/$mod_string/) { $modification{$pep}.="$mod_string,"; }
						}
					}
					close(IN);
				}
			}
			$counter=0;
			$sample_="";
			foreach my $key(sort keys %samples)
			{
				$counter++;
				$sample_="sample"."$counter";  
				$sampleprotfilename="sampleprot"."$counter"."-".$ip."-".$datetime; 
				$sampleprotfilename=~s/([\s\:\.]+)/\-/g;
				$sample_="sample"."$counter";  
				$samplepepfilename="samplepep"."$counter"."-".$ip."-".$datetime; 
				$samplepepfilename=~s/([\s\:\.]+)/\-/g;	
				$samplefilename="sample"."$counter"."-".$ip."-".$datetime; 
				$samplefilename=~s/([\s\:\.]+)/\-/g;
				open(OUT,qq!>$sampleprotfilename!);
				open(OUT1,qq!>$samplepepfilename!); 
				open(OUT2,qq!>$samplefilename!); 
				$temp=$samples{$key};
				while($temp=~s/#([^#]+)#//)
				{ 
					$value=$1; 
					$xmlfile=$value;
					print OUT2 qq!$xmlfile\n!;
					open(IN,qq!$xmlfile!); 
					while($line=<IN>)
					{
						if($line=~/<group.*label="([^\s]+)" type="([^\"]+)" sumI="([^\"]+)".*>/)
						{
							#$prot_name=$1;
							$group_type=$2;
							$group_sumI=$3;
						}
						elsif($line=~/<protein expect="([\-0-9\.0-9]+)" .*label="([^\"]+)" .*sumI="([0-9\.0-9]+)" /)
						{
							$exp_prot=$1; 
							$prot_label=$2;
							$sumI=$3; 
							if($prot_label=~/([^\s]+)/) {  $prot_name=$1; }
						}
						elsif($line=~/<note label="description">(.*)<\/note>/)
						{
							$protein_description{$prot_name}="$1";
						}
						elsif($line=~/<domain id.*expect="([0-9\.\-\+edED]+)" mh="([^\"]+)" delta="([^\"]+)".*seq="([A-Za-z]+)".*>/) 
						{
							$exp_pep=log($1)/log(10); 
							$mh=$2;
							$delta=$3;
							$pep=$4;
							$pep=~tr/L/I/; 
						}
						elsif($line=~/<\/domain>/)
						{
							if (!$modification{$pep}) { $modification{$pep}="none"; }
							{	
								if($unique_pep_count_sample{"$prot_name#$sample_"}!~/\w/) { $unique_pep_count_sample{"$prot_name#$sample_"}=0;}
								if($total_pep_count_sample{"$prot_name#$sample_"}!~/\w/) { $total_pep_count_sample{"$prot_name#$sample_"}=0; }
								$value="&$sample_&&$pep&&$modification{$pep}&";  
								if($pep_exp_sample{$prot_name}{$exp_pep}!~m/$value/ and $exp_pep==$min_pep_exp_sample{"$prot_name#$pep#$sample_"})
								{  
									if($prot_sample{$prot_name}!~/\w/ and $exp_prot==$min_prot_exp_sample{"$prot_name#$sample_"}) 
									{	
										$prot_sample{$prot_name}="$exp_prot#$sumI"; 
									}  	
									$protein_filename{"$prot_name#$sample_"}="$exp_prot#$sumI"; 
									$pep_exp_sample{$prot_name}{$exp_pep}.="#&$sample_&&$pep&&$modification{$pep}&&$exp_pep&&$sumI&&$mh&&$delta&#"; 
									print OUT qq!$prot_name\t$protein_filename{"$prot_name#$sample_"}\n!;
									print OUT1 qq!$prot_name\t$pep\t$pep_exp_sample{$prot_name}{$exp_pep}\n!;
								}
								if($peptides_sample{"$prot_name#$pep#$sample_"}!~/\w/) { $peptides_sample{"$prot_name#$pep#$sample_"}="$pep"; $unique_pep_count_sample{"$prot_name#$sample_"}++; }
								$total_pep_count_sample{"$prot_name#$sample_"}++; 
							} 
						}
						elsif($line=~/<\/group>/)
						{  
							$pep="";
							$exp_pep="";
							$mh="";
							$delta="";
							$pre="";
							$post="";
							$exp_prot=""; 
							$prot_name="";
							$group_type="";
							$group_sumI="";
							$sumI="";
						}
					}
					close(IN);
				}
				close(OUT);
				close(OUT1);
				close(OUT2);
			}
		}
	}
	$status="CreateReportStep3"; 
}
if ($status=~/^CreateReportStep3$/)   
{
	my $project_id=$query->param("project_id");
	my $prot_cutoff=$query->param("prot_cutoff");
	my $pep_cutoff=$query->param("pep_cutoff");
	my $i_prot=0;
	print qq!
	<FORM ACTION="pipeline_cgi_reports.pl" METHOD="post" ENCTYPE="multipart/form-data" NAME="myform">
	<INPUT TYPE="hidden" NAME="prot_cutoff" VALUE="$prot_cutoff">
	<INPUT TYPE="hidden" NAME="pep_cutoff" VALUE="$pep_cutoff">
	<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
	<b>Create Reports (Step 3)<br>Report</b>&nbsp;&nbsp;&nbsp;
	<INPUT TYPE="submit" NAME="submit" VALUE="Next"><br><br>
	!;   
	print qq!
			<script language="javascript" type="text/javascript">
			function checkAll(field)
			{
				for (i = 0; i < field.length; i++)
				field[i].checked = true ;
			}

			function uncheckAll(field)
			{
				for (i = 0; i < field.length; i++)
				field[i].checked = false ;
			}
			</script>
		!; 
	print qq!
	<input type=button NAME="CheckAll" value="Check All" onClick="checkAll(document.myform.prots)">
	<input type=button NAME="UnCheckAll" value="Uncheck All" onClick="uncheckAll(document.myform.prots)">
	!;	
	print qq!<table border="1" bordercolor="darkgoldenrod">!;
	print qq!<tr><td><b>Rank</b></td><td><b>Accession</b></td><td><b>Description</b></td>!;
	for(my $i=1;$i<=$sample_count;$i++)
	{
		print qq!<td><b>Sample$i</b><br>!;
		$temp=$samples{$i};
		while($temp=~s/#([^#]+)#//)
		{
			$value = $1;
			if($value=~/([^\/]+)$/) { print qq!$1<br>!; }
		}
		print qq!</td>!;
	}
	print qq!</tr>!;
	print qq!<tr><td></td><td></td><td></td>!; 
	for(my $i=1;$i<=$sample_count;$i++)
	{
		print qq!<td><i>log(e)&nbsp;&nbsp;&nbsp;&nbsp;#&nbsp;&nbsp;&nbsp;&nbsp;Total&nbsp;&nbsp;&nbsp;&nbsp;log(I)</i></td>!;
	}
	print qq!</tr>!;
	
	for(my $i=1;$i<=$sample_count;$i++)
	{
		$sample_num="sample".$i;
		$sampletotalfile = "sampletotal".$i."-".$ip."-".$datetime;
		$sampletotalfile =~s/([\s\:\.]+)/\-/g;
		$sampleuniquefile = "sampleunique".$i."-".$ip."-".$datetime;
		$sampleuniquefile =~s/([\s\:\.]+)/\-/g;	
		$sampleprotfilename="sampleprot".$i."-".$ip."-".$datetime; 
		$sampleprotfilename =~s/([\s\:\.]+)/\-/g;	
		$samplepepfilename="samplepep".$i."-".$ip."-".$datetime; 
		$samplepepfilename =~s/([\s\:\.]+)/\-/g;
		$samplefilename="sample".$i."-".$ip."-".$datetime; 
		$samplefilename=~s/([\s\:\.]+)/\-/g;
		open(OUT1,qq!>$sampletotalfile!);
		open(OUT2,qq!>$sampleuniquefile!);
		foreach my $prots(keys %prot_sample) 
		{
			if($prot_sample{$prots}=~/\w/)
			{ 
				print OUT1 qq!$prots\t$total_pep_count_sample{"$prots#$sample_num"}\n!; 
				print OUT2 qq!$prots\t$unique_pep_count_sample{"$prots#$sample_num"}\n!;
			}
		}
		close(OUT1);
		close(OUT2);
	}
	
	foreach my $prots(keys %prot_sample) 
	{
		$i_prot++;
		print qq!<tr valign="top"><td>$i_prot</td>!; 
		print qq!<td><INPUT TYPE="checkbox" NAME="prots" VALUE="$prots" checked>&nbsp;!;
		print qq!<INPUT TYPE="hidden" NAME="prot_description$prots" VALUE="$protein_description{$prots}" checked>&nbsp;!;
		print qq!$prots<br>!; 
		print qq!<td>$protein_description{$prots}</td>!;
		for(my $i=1;$i<=$sample_count;$i++)
		{
			$sample_num="sample".$i;
			$sampletotalfile = "sampletotal".$i."-".$ip."-".$datetime;
			$sampletotalfile =~s/([\s\:\.]+)/\-/g;
			$sampleuniquefile = "sampleunique".$i."-".$ip."-".$datetime;
			$sampleuniquefile =~s/([\s\:\.]+)/\-/g;	
			$sampleprotfilename="sampleprot".$i."-".$ip."-".$datetime; 
			$sampleprotfilename =~s/([\s\:\.]+)/\-/g;	
			$samplepepfilename="samplepep".$i."-".$ip."-".$datetime; 
			$samplepepfilename =~s/([\s\:\.]+)/\-/g;
			$samplefilename="sample".$i."-".$ip."-".$datetime; 
			$samplefilename=~s/([\s\:\.]+)/\-/g;
			if($prot_sample{$prots}=~/\w/)
			{ 
				if($protein_filename{"$prots#$sample_num"}=~/\w/)
				{
					my $proteins=$protein_filename{"$prots#$sample_num"}; 
					if($proteins=~/([^#]+)#([^#]+)/)
					{
						{
							$exp_sample=$1; 
							$intensity=$2;
						}
					}
					$id_sample=$sample_num.$prots.$exp_sample.$intensity;
					print qq!
						<script language="javascript" type="text/javascript">
						function toggle_visibility(id,obJect) 
						{
						   var e = document.getElementById(id);
						   if(e.style.display == 'none')
						   {
							  e.style.display = 'inline-table';
							  if(obJect){ obJect.src = '/pics/ffa_expanded.gif'; }
						   }
						   else
						   {
							  e.style.display = 'none';
							  if(obJect){ obJect.src = '/pics/ffa_collapsed.gif'; }
						   }
						}
						</script>
					!;
					print qq!<td><img  src='/pics/ffa_collapsed.gif' onClick="toggle_visibility('$id_sample',this);" title="click to show or hide form information"/>!;
					print qq!$exp_sample&nbsp;&nbsp;&nbsp;&nbsp;!;
					print qq!$unique_pep_count_sample{"$prots#$sample_num"}&nbsp;&nbsp;&nbsp;&nbsp;!;
					print qq!$total_pep_count_sample{"$prots#$sample_num"}&nbsp;&nbsp;&nbsp;&nbsp;!;
					print qq!$intensity&nbsp;&nbsp;&nbsp;&nbsp;!;
					print qq!<div style="display:none" id="$id_sample"> !;
					print qq!<table border="1" bordercolor="darkkhaki"><tr>!;
					print qq!<b><td></td>
								<td>&nbsp;&nbsp;&nbspSequence</td>
								<td>&nbsp;&nbsp;&nbsp;Modification</td>
								<td>&nbsp;&nbsp;&nbsp;log(e)</td>
								<td>&nbsp;&nbsp;&nbsp;log(I)</td>
								<td>&nbsp;&nbsp;&nbsp;m+h</td>
								<td>&nbsp;&nbsp;&nbsp;delta</td></tr></b>!;
					foreach my $sorted(sort {$a <=> $b} keys %{ $pep_exp_sample{$prots} })
					{   
						my $peptide=$pep_exp_sample{$prots}{$sorted}; 
						while($peptide=~s/#([^#]+)#//)
						{
							my $temp=$1;
							if($temp=~/&([^&]+)&&([^&]+)&&([^&]+)&&([^&]+)&&([^&]+)&&([^&]+)&&([^&]+)&/)
							{
								my $samplename=$1;
								my $pep_=$2;
								my $mod_=$3;
								my $exp_=$4;
								my $sumI_=$5;
								my $mh_=$6;
								my $delta_=$7; 
								my $protpep=$prots.$samplename; 
								if($samplename eq $sample_num)
								{ 	
									print qq!<tr>!; 
									print qq!<td><INPUT TYPE="checkbox" NAME="pepsample$protpep" VALUE="$pep_" checked></td>!;
									print qq!<td><font size=-1>$pep_</font>&nbsp;&nbsp;&nbsp;</td>!;
									print qq!<td><font size=-1>$mod_</font>&nbsp;&nbsp;&nbsp;</td>!;
									print qq!<td><font size=-1>$exp_</font>&nbsp;&nbsp;&nbsp;</td>!;
									print qq!<td><font size=-1>$sumI_</font>&nbsp;&nbsp;&nbsp;</td>!;
									print qq!<td><font size=-1>$mh_</font>&nbsp;&nbsp;&nbsp;</td>!;
									print qq!<td><font size=-1>$delta_</font>&nbsp;&nbsp;&nbsp;</td>!;
									print qq!</tr>!;
								}
							}
						} 
					} 
					print qq!</table>!;
					print qq!</div>!; print qq!</td>!;
				}
				else
				{
					print qq!<td></td>!;
				} 
				print qq!<INPUT TYPE="hidden" NAME="sampleprot$i" VALUE="$sampleprotfilename">!; 
				print qq!<INPUT TYPE="hidden" NAME="samplepep$i" VALUE="$samplepepfilename">!; 
				print qq!<INPUT TYPE="hidden" NAME="sampletot$i" VALUE="$sampletotalfile">!;	
				print qq!<INPUT TYPE="hidden" NAME="sampleuni$i" VALUE="$sampleuniquefile">!;
				print qq!<INPUT TYPE="hidden" NAME="sample$i" VALUE="$samplefilename">!; 
			}
		}
		print qq!</tr>!;
	}
	print qq!</table>!;	
	print qq!<INPUT TYPE="hidden" NAME="samplesize" VALUE="$sample_count">!;
	print qq!<INPUT TYPE="hidden" NAME="status" VALUE="CreateReportStep4">!; 
	print qq!</FORM>!;
	
}
if ($status=~/^CreateReportStep4$/)   
{
	my $project_id=$query->param("project_id");
	my $prot_cutoff=$query->param("prot_cutoff");
	my $pep_cutoff=$query->param("pep_cutoff");
	my $sample_count=$query->param("samplesize");
	my @prot=$query->param("prots");
	my $i=1;
	my $datetime = GetDateTime();
	my $temp = "report-".$ip."-".$datetime;
	$temp =~s/([\s\:\.]+)/\-/g;
	$temp = $temp.".html";
	my %protein_sample=();
	my %peptide_sample=();
	my %sample_total=();
	my %sample_unique=();
	my %samples=();
	open(TEMP,qq!>$temp!);
	
	print qq!
		<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data" NAME="myform">
		<INPUT TYPE="hidden" NAME="status" VALUE="ViewExperiment">
		<INPUT TYPE="hidden" NAME="prot_cutoff" VALUE="$prot_cutoff">
		<INPUT TYPE="hidden" NAME="pep_cutoff" VALUE="$pep_cutoff">
		<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		<INPUT TYPE="hidden" NAME="reportfile" VALUE="$temp">
		<b>Create Reports (Step 4)</b>
		<button onclick="saveReport()">Save Report</button><br><br>
	!; 
	
	############# writing to temp file for saving report begins ##########
	print TEMP qq!
		<FORM ACTION="pipeline_cgi.pl" METHOD="post" ENCTYPE="multipart/form-data" NAME="myform">
		<INPUT TYPE="hidden" NAME="status" VALUE="ViewExperiment">
		<INPUT TYPE="hidden" NAME="prot_cutoff" VALUE="$prot_cutoff">
		<INPUT TYPE="hidden" NAME="pep_cutoff" VALUE="$pep_cutoff">
		<INPUT TYPE="hidden" NAME="project_id" VALUE="$project_id">
		<b>Report</b><br><br>
	!; 
	############# writing to temp file for saving report ends ##########
	
	for(my $i=1;$i<=$sample_count;$i++)
	{
		my $sampleprot=$query->param("sampleprot$i"); 
		my $samplepep=$query->param("samplepep$i"); 
		my $sampletotal=$query->param("sampletot$i"); 
		my $sampleunique=$query->param("sampleuni$i");  
		my $samplefile=$query->param("sample$i");
		open(IN,qq!$samplefile!); 
		while($line=<IN>)
		{
			chomp($line); 
			if($line=~/\/([^\/]+)$/)
			{
				my $name=$1;
				$samples{$i}.="#$name#";
			}
		}
		close(IN);
		open(IN,qq!$sampleprot!);
		while($line=<IN>)
		{
			if($line=~/([^\t]+)\t([^\t]+)/)
			{
				my $name=$1;
				my $exp=$2;
				$protein_sample{"sample$i"}{$name}=$exp;
			}
		}
		close(IN);
		open(IN,qq!$samplepep!);
		while($line=<IN>)
		{
			if($line=~/([^\t]+)\t([^\t]+)\t([^\t]+)/)
			{
				my $name=$1;
				my $pep=$2;
				my $list=$3;
				$peptide_sample{"sample$i"}{$name}{$pep}=$list;
			}
		}
		close(IN);
		open(IN,qq!$sampletotal!);
		while($line=<IN>)
		{
			if($line=~/([^\t]+)\t([^\t]+)/)
			{
				my $name=$1;
				my $total=$2;
				$sample_total{"sample$i"}{$name}=$total;
			}
		}
		close(IN);
		open(IN,qq!$sampleunique!);
		while($line=<IN>)
		{
			if($line=~/([^\t]+)\t([^\t]+)/)
			{
				my $name=$1;
				my $unique=$2;
				$sample_unique{"sample$i"}{$name}=$unique;
			}
		}
		close(IN);
	}
	print qq!<table border=1 bordercolor=darkolivegreen>!; 
	print TEMP qq!<table border=1 bordercolor=darkolivegreen>!;
	print qq!<tr><td><b>Rank</b></td><td><b>Accession</b></td><td><b>Description</b></td>!;
	print TEMP qq!<tr><td><b>Rank</b></td><td><b>Accession</b></td><td><b>Description</b></td>!;
	for(my $i=1;$i<=$sample_count;$i++)
	{
		print qq!<td><b>Sample$i</b><br>!;
		print TEMP qq!<td><b>Sample$i</b><br>!;
		$temp=$samples{$i};
		while($temp=~s/#([^#]+)#//)
		{
			$value = $1;
			if($value=~/([^\/]+)$/) { print qq!$1<br>!; print TEMP qq!$1<br>!; }
		}
		print qq!</td>!;
		print TEMP qq!</td>!;
	}
	print qq!</tr>!;
	print TEMP qq!</tr>!;
	print qq!<td></td><td></td><td></td>!;
	print TEMP qq!<td></td><td></td><td></td>!;
	for(my $i=1;$i<=$sample_count;$i++)
	{
		print qq!<td><i>log(e)&nbsp;&nbsp;&nbsp;&nbsp;#&nbsp;&nbsp;&nbsp;&nbsp;Total&nbsp;&nbsp;&nbsp;&nbsp;log(I)</i></td>!;
		print TEMP qq!<td><i>log(e)&nbsp;&nbsp;&nbsp;&nbsp;#&nbsp;&nbsp;&nbsp;&nbsp;Total&nbsp;&nbsp;&nbsp;&nbsp;log(I)</i></td>!;
	}
	print qq!</tr>!;
	print TEMP qq!</tr>!;
	
	foreach my $key(@prot)
	{
		print qq!<tr valign="top"><td>$i</td><td>$key<br>!;
		print TEMP qq!<tr valign="top"><td>$i</td><td>$key<br>!;
		$i++;
		print qq!
						<script language="javascript" type="text/javascript">
						function toggle_visibility(id,obJect) 
						{
						   var e = document.getElementById(id);
						   if(e.style.display == 'none')
						   {
							  e.style.display = 'inline-table';
							  if(obJect){ obJect.src = '/pics/ffa_expanded.gif'; }
						   }
						   else
						   {
							  e.style.display = 'none';
							  if(obJect){ obJect.src = '/pics/ffa_collapsed.gif'; }
						   }
						}
						</script>
		!;
		print TEMP qq!
		
						<script language="javascript" type="text/javascript">
						function toggle_visibility(id,obJect) 
						{
						   var e = document.getElementById(id);
						   if(e.style.display == 'none')
						   {
							  e.style.display = 'inline-table';
							  if(obJect){ obJect.src = '/pics/ffa_expanded.gif'; }
						   }
						   else
						   {
							  e.style.display = 'none';
							  if(obJect){ obJect.src = '/pics/ffa_collapsed.gif'; }
						   }
						}
						</script>
		!;
		my $prot_description=$query->param("prot_description$key");
		print qq!<td>$prot_description</td>!;
		print TEMP qq!<td>$prot_description</td>!; 
		
		for(my $i=1;$i<=$sample_count;$i++)
		{
			my $protpep_=$key."sample".$i;
			my @pep_sample=$query->param("pepsample$protpep_"); 
			if($protein_sample{"sample$i"}{$key}=~/([^#]+)#([^#]+)/) 
			{ 
				my $expectation=$1; 
				my $intensity=$2;
				$intensity=~s/\s+//;
				my $id_sample="sample".$i.$key.$expectation.$intensity;
				print qq!
						<script language="javascript" type="text/javascript">
						function toggle_visibility(id,obJect) 
						{
						   var e = document.getElementById(id);
						   if(e.style.display == 'none')
						   {
							  e.style.display = 'inline-table';
							  if(obJect){ obJect.src = '/pics/ffa_expanded.gif'; }
						   }
						   else
						   {
							  e.style.display = 'none';
							  if(obJect){ obJect.src = '/pics/ffa_collapsed.gif'; }
						   }
						}
						</script>
					!;
				print TEMP qq!
						<script language="javascript" type="text/javascript">
						function toggle_visibility(id,obJect) 
						{
						   var e = document.getElementById(id);
						   if(e.style.display == 'none')
						   {
							  e.style.display = 'inline-table';
							  if(obJect){ obJect.src = '/pics/ffa_expanded.gif'; }
						   }
						   else
						   {
							  e.style.display = 'none';
							  if(obJect){ obJect.src = '/pics/ffa_collapsed.gif'; }
						   }
						}
						</script>
					!;
				print qq!<td><img  src='/pics/ffa_collapsed.gif' onClick="toggle_visibility('$id_sample',this);" title="click to show or hide form information"/>!;
				print TEMP qq!<td><img  src='/pics/ffa_collapsed.gif' onClick="toggle_visibility('$id_sample',this);" title="click to show or hide form information"/>!;
				print qq!$expectation&nbsp;&nbsp;&nbsp;&nbsp;!;
				print TEMP qq!$expectation&nbsp;&nbsp;&nbsp;&nbsp;!;
				print qq!$sample_unique{"sample$i"}{$key}&nbsp;&nbsp;&nbsp;&nbsp;!;
				print TEMP qq!$sample_unique{"sample$i"}{$key}&nbsp;&nbsp;&nbsp;&nbsp;!;
				print qq!$sample_total{"sample$i"}{$key}&nbsp;&nbsp;&nbsp;&nbsp;!;
				print TEMP qq!$sample_total{"sample$i"}{$key}&nbsp;&nbsp;&nbsp;&nbsp;!;
				print qq!$intensity!;
				print TEMP qq!$intensity!;
				print qq!<div style="display:none" id="$id_sample">!;
				print TEMP qq!<div style="display:none" id="$id_sample">!;
				if(@pep_sample)
				{ 
					print qq!<table border=1 bordercolor=darkkhaki>!;
					print TEMP qq!<table border=1 bordercolor=darkkhaki>!; 
					print qq!<tr valign="top"><td><i>Peptides</i></td><td><i>Modification</i></td><td><i>Exp</i></td><td><i>sumI</i></td><td><i>mh</i></td><td><i>delta</i></td></tr>!;
					print TEMP qq!<tr valign="top"><td><i>Peptides</i></td><td><i>Modification</i></td><td><i>Exp</i></td><td><i>sumI</i></td><td><i>mh</i></td><td><i>delta</i></td></tr>!;
					foreach my $key_sample(@pep_sample) 
					{														
						if($peptide_sample{"sample$i"}{$key}{$key_sample}=~/#&([^&]+)&&([^&]+)&&([^&]+)&&([^&]+)&&([^&]+)&&([^&]+)&&([^&]+)&#/) 
						{
							$three=$3; 
							$four=$4;
							$five=$5;
							$six=$6;
							$seven=$7;
						}
						print qq!<tr valign="top"><td><FONT size=-1>$key_sample</td><td>$three</td><td>$four</td><td>$five</td><td>$six</td><td>$seven</FONT></td></tr>!;
						print TEMP qq!<tr valign="top"><td><FONT size=-1>$key_sample</td><td>$three</td><td>$four</td><td>$five</td><td>$six</td><td>$seven</FONT></td></tr>!;
						
					}
					print qq!</table>!;
					print TEMP qq!</table>!;
				}
				print qq!</div>!;
				print TEMP qq!</div>!;
				print qq!</td>!;
				print TEMP qq!</td>!;
			}
			else
			{
				print qq!<td></td>!;
				print TEMP qq!<td></td>!;
			}
		}
	}
	print qq!</table>!;	
	print TEMP qq!</table>!;				
	print qq!</FORM>!;	
	print TEMP qq!</FORM>!;	
	close(TEMP);
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
	my $date="$year-$mon-$mday-$hour-$min-$sec";
	
	return $date;
}