#!c:/perl/bin/perl.exe
#
use strict;

my $error=0;
my $xmltextfile="";
my $mgftextfile="";
my %mz_xml=();
my %mz_xml_info=();
my %mz_mgf=();
my %mz_mgf_info=();
my %intensity_mgf=();
my %list=();
my %peptides=();
my %mz_time_xml=();  
my $max_int=0;
my $delta_mz=100;
my $delta_time=500/60;
my %mz_time_mgf=();
my %used_protein_labels=();
my %label=();
my $protein_labels="";
my $dir="";
open(LOG,qq!>log.txt!);
if ($ARGV[0]=~/\w/) { $xmltextfile=$ARGV[0];} else { $error=1; }
if ($ARGV[1]=~/\w/) { $mgftextfile=$ARGV[1];} else { $error=1; }
if ($ARGV[2]=~/\w/) { $dir=$ARGV[2];} else { $error=1; }
my $xmltextfile_=$xmltextfile; 
$xmltextfile_=~s/\.basepeak\.txt$//;
my $line="";
my $method_file="";
my $taxon=""; 
if ($error==0)
{
	if (opendir(dir,"$dir"))
	{  
		my @allfiles=readdir dir;
		closedir dir; 
		foreach my $file (@allfiles)
		{	
			if ($file=~/.*\-analysis\.xml$/i)
			{	
				open (IN,qq!$dir/$file!) || die "Could not open file $file\n"; 
				while($line=<IN>)
				{
					if($line=~/<step type="ID" .* method='.*\/([^\/]+).xml'\/>/)
					{
						$method_file=$1."\.xml"; 
						open (IN1,qq!$dir/$method_file!) || die "Could not open file $file\n"; 
						while($line=<IN1>)
						{
							if($line=~/<note type="input" label="protein, taxon">(.*)<\/note>/)
							{
								$taxon=$1; 
							}					
						}
						close(IN1);
					}					
				}
				close(IN);
			}
		}
	}
	open(TAXON,qq!D:/Server/thegpm/tandem/taxonomy.xml!);
	while($line=<TAXON>)
	{
		if($line=~/<taxon label="([^\"]+)">/)
		{
			my $taxon_=$1;
			if($taxon_ eq $taxon)
			{
				do
				{ 	
					$line=<TAXON>;
					if($line=~/<file format="peptide" URL="([^\"]+)" \/>/)
					{
						my $database=$1; 
						if (open(LABEL,qq!$database-label.txt!))
						{  
							while($line=<LABEL>)
							{
								chomp($line);
								if($line=~/([^\t]+)\t([^\t]+)/)
								{
									my $genes=$1;
									my $prots_=$2;
									$label{$prots_}="$genes";  
								}
							}
							close(LABEL);
						}
					}
				}
				while($line!~/<\/taxon>/);
			}
		}
	}
	close(TAXON);
	
	my $mz="";
	my $scan="";
	my $time="";
	my $proteins="";
	my $pep="";
	my $intensity="";
	open (IN,qq!$xmltextfile!) || die "Could not open xml $xmltextfile\n";
	while ($line=<IN>)
	{
		if($line=~/([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\n/ and $line!~/scan	time	pep	mz	proteins/)
		{
			$mz=$4;
			$scan=$1;
			$time=$2;
			$pep=$3;
			$proteins=$5;
			$mz_xml_info{$scan}="$1,$2,$3,$4,$5";
			$mz_time_xml{$scan}=$time;  
			$peptides{$scan}=$pep;
			$mz_xml{$scan}=$mz;
		}
	}	
	close(IN);	
	
	my %ms2_time=();
	my %ms2_charge=();
	my %ms2_mz=();
	my $xmltextfile_=$xmltextfile;
	$xmltextfile_=~s/\.xml\.basepeak\.txt$/.mgf.basepeak.txt/i;
	open (IN,qq!$xmltextfile_!) || die "Could not open xml $xmltextfile_\n";
	while ($line=<IN>)
	{
		if($line=~/([^\t]+)\t([^\t]+)\t([^\t]*)\t([^\t]+)/ and $line!~/scan	time	charge	mz/)
		{
			my $scan=$1;
			my $time=$2;
			my $charge=$3;
			my $mz=$4;
			if ($charge!~/\+/) { $charge="+$charge"; }
			if ($mz>0)
			{
				$ms2_time{$scan}=$time;  
				$ms2_charge{$scan}=$charge;
				$mz=10*$mz+0.5;
				$mz=int($mz);
				$mz/=10;
				$ms2_mz{$scan}=$mz;
				#print qq!#$scan $time $charge $mz#\n!;
			}
		}
	}	
	close(IN);	

	open (IN,qq!$mgftextfile!) || die "Could not open mgf $mgftextfile\n";
	while ($line=<IN>)
	{
		if($line=~/([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\n/ and $line!~/scan	time	mz	intensity/)
		{
			my $intensity_=$4;
			if($max_int < $intensity_)
			{
				$max_int = $intensity_;
			}
		}
	}	
	close(IN);	
	my $lower_limit=0;
	my $upper_limit=0;
	my @basepeak_time=();
	my @basepeak_intensity=();
	my $basepeak_count=0;
	$mz="";
	$scan="";
	$time="";
	open (IN,qq!$mgftextfile!) || die "Could not open $mgftextfile\n";
	open (OUT,qq!>$xmltextfile_.labelled.basepeak.txt!) || die "Could not open out file\n";
	print OUT qq!scan\ttime\tmz\tintensity\n!;
	while ($line=<IN>)
	{
		if($line=~/([^\t]+)\t([^\t]+)\t([^\t]+)\t([^\t]+)\n/ and $line!~/scan	time	mz	intensity/)
		{
			$mz=$3;
			$scan=$1;
			$time=$2;
			$intensity=$4;
			print OUT qq!$line!;
			if($intensity > 0.03*$max_int)
			{
				if ($lower_limit==0) { $lower_limit=$time; }
				$upper_limit=$time;
			}
			if($intensity > 0.01*$max_int)
			{
				$intensity_mgf{$scan}="$4";
				$mz_mgf_info{$scan}="$1,$2,$3,$4";
				$mz_time_mgf{$scan}=$time;
				$mz_mgf{$scan}=$mz;
			}
			$basepeak_time[$basepeak_count]=$time;
			$basepeak_intensity[$basepeak_count]=$intensity;
			$basepeak_count++;
		}
	}	
	close(IN);
	close(OUT);
	open (OUT,qq!>$xmltextfile_.labelled.basepeak..txt!) || die "Could not open text file\n";
	open (OUT1,qq!>$xmltextfile_.identified.basepeak.txt!) || die "Could not open text file\n";
	print OUT qq!scan_mgf,time_mgf,mz_mgf,intensity_mgf\tscan_xml,time_xml,pep_xml,mz_xml,proteins_xml\n!;
	print OUT1 qq!intensitymgf\ttimemgf\tpeptides\n!;
	my %done=();
	foreach my $scan_mgf (keys %mz_mgf)
	{	
		my $mzmgf=$mz_mgf{$scan_mgf};
		foreach my $scan_xml(keys %mz_xml)
		{	
			my $mzxml=$mz_xml{$scan_xml};
			if( abs(($mzmgf-$mzxml)*1e+6/$mzxml)< $delta_mz and abs($mz_time_mgf{$scan_mgf}-$mz_time_xml{$scan_xml})< $delta_time)
			{
				print OUT qq!$mz_mgf_info{$scan_mgf}\t$mz_xml_info{$scan_xml}\n!;
				print OUT1 qq!$intensity_mgf{$scan_mgf}\t$mz_time_mgf{$scan_mgf}\t$peptides{$scan_xml}\n!;
				if($mz_xml_info{$scan_xml}=~/([^\,]+)\,([^\,]+)\,([^\,]+)\,([^\,]+)\,(.*)$/)
				{
					$protein_labels=$5;
				}
				$list{$peptides{$scan_xml}}.="\*$intensity_mgf{$scan_mgf},$mz_time_mgf{$scan_mgf},$protein_labels\*";
				$done{$scan_mgf}=$intensity_mgf{$scan_mgf};
			}
		}
	}
	foreach my $scan_mgf (keys %mz_mgf)
	{	
		if ($done{$scan_mgf}!~/\w/)
		{
			my $mzmgf=$mz_mgf{$scan_mgf};
			foreach my $ms2_scan (keys %ms2_mz)
			{
				if ($ms2_mz{$ms2_scan}>0)
				{
					if( abs(($mzmgf-$ms2_mz{$ms2_scan})*1e+6/$ms2_mz{$ms2_scan})< $delta_mz and abs($mz_time_mgf{$scan_mgf}-$ms2_time{$ms2_scan})< $delta_time)
					{
						$list{"$ms2_mz{$ms2_scan} $ms2_charge{$ms2_scan}"}.="\*$intensity_mgf{$scan_mgf},$mz_time_mgf{$scan_mgf},\*";
					}
				}
			}
		}
	}
	close(OUT);
	close(OUT1);
	
	my @labels=();
	my $label_count=0;
	my @labels_mz=();
	my $label_mz_count=0;
	my %used_prots=(); 
	open (OUT,qq!>$xmltextfile_.labelpeak_.basepeak.txt!) || die "Could not open text file\n";
	print OUT qq!maxpeptides\tmaxintensity\tmaxtime\n!;
	foreach my $peptide(sort keys %list)
	{
		my $max_int=0; 
		my $max_time=0; 
		my $pepmz = $list{$peptide}; 
		my $protein="";
		my $flag=0;
		my $prots="";
		my $sp_found="";
		while($pepmz=~s/\*([^\,]+)\,([^\,]+)\,([^\*]*)\*//)
		{
			my $intensity=$1; 
			my $time=$2;
			$protein=$3;  
			if($intensity > $max_int) 
			{ 
				$max_int = $intensity; 
				$max_time = $time; 
			}
		} 
		my $protein_=$protein;
		while($protein_=~s/#([^#]+)#//)
		{
			$prots=$1;
			if ($prots=~/^sp\|/)
			{
				$used_protein_labels{$prots}=$prots;
			}
		}
		while($protein=~s/#([^#]+)#//)
		{
			$prots=$1;
			if($used_protein_labels{$prots}=~/\w/) 
			{ 
				$flag=1; 
				$used_prots{$peptide}=$used_protein_labels{$prots};
			}
		}
		if($flag==0)
		{
			if($label{$prots}=~/\w/)
			{
				$used_protein_labels{$prots}="\U$label{$prots}"; 
				$used_prots{$peptide}="\U$label{$prots}";
				print LOG qq!$used_prots{$peptide}\t$used_protein_labels{$prots}\n!;		
			}
			else
			{
				$used_protein_labels{$prots}="$prots";
				$used_prots{$peptide}="$prots";
			}	
		}
		my $index_max=0;
		for(;$index_max<$basepeak_count and $basepeak_time[$index_max]<=$max_time;$index_max++) {}
		my $index_plus=$index_max;
		for(;$basepeak_intensity[$index_plus]>=0.5*$basepeak_intensity[$index_max] and $basepeak_intensity[$index_plus]<1.2*$basepeak_intensity[$index_max] and $index_plus<$basepeak_count;$index_plus++) {}
		my $index_minus=$index_max;
		for(;$basepeak_intensity[$index_minus]>=0.5*$basepeak_intensity[$index_max] and $basepeak_intensity[$index_minus]<1.2*$basepeak_intensity[$index_max] and $index_minus>=0;$index_minus--) {}
		if ($max_int>0)
		{
			if ($peptide=~/^[A-Z]/)
			{
				$labels[$label_count++]=qq!$max_int#$max_time#$peptide#$index_max#$index_minus#$index_plus#$used_prots{$peptide}!;
			}
			else
			{
				$labels_mz[$label_mz_count++]=qq!$max_int#$max_time#$peptide#$index_max#$index_minus#$index_plus#$used_prots{$peptide}!;
				#print qq!-----$peptide-$max_int-\n!;
			}
		}
	}
	my @done=();
	foreach my $label (sort {$b<=>$a} @labels)
	{
		print qq!---###---$label\n!;
		if ($label=~/^([^\#]+)#([^\#]+)#([^\#]+)#([^\#]+)#([^\#]+)#([^\#]+)#([^\#]*)$/)
		{
			my $max_int=$1;
			my $max_time=$2;
			my $peptide=$3;
			my $index_max=$4;
			my $index_minus=$5;
			my $index_plus=$6;
			my $proteins=$7;
			if($proteins=~/(.*)\sOS=.*/)
			{
				$proteins=$1;
			}
			if ($done[$index_max]!~/\w/)
			{
				print OUT qq!$peptide      $proteins\t$max_int\t$max_time\n!;
				my $i=int($index_max-1.7*($index_max-$index_minus));
				if ($i<0) { $i=0; }
				for(;$i<=$index_max+1.7*($index_plus-$index_max);$i++) { $done[$i]=$max_int; }
			}
		}
	}	
	foreach my $label (sort {$b<=>$a} @labels_mz)
	{
		print qq!---$label\n!;
		if ($label=~/^([^\#]+)#([^\#]+)#([^\#]+)#([^\#]+)#([^\#]+)#([^\#]+)#([^\#]*)$/)
		{
			my $max_int=$1;
			my $max_time=$2;
			my $peptide=$3;
			my $index_max=$4;
			my $index_minus=$5;
			my $index_plus=$6;
			my $proteins=$7;
			if($proteins=~/(.*)\sOS=.*/)
			{
				$proteins=$1;
			}
			print qq!--#$done[$index_max]#--$label\n!;
			if (1.2*$done[$index_max]<$max_int)
			{
				print OUT qq!$peptide      $proteins\t$max_int\t$max_time\n!;
				my $i=int($index_max-1.7*($index_max-$index_minus));
				if ($i<0) { $i=0; }
				for(;$i<=$index_max+1.7*($index_plus-$index_max);$i++) { $done[$i]=$max_int; }
			}
		}
	}
	close(OUT);
	
	my $line_counter=0;
	open(IN,qq!$xmltextfile_.labelpeak_.basepeak.txt!);
	open(OUT,qq!>$xmltextfile_.labelpeak.basepeak.txt!);
	while($line=<IN>)
	{
		if($line_counter<=25)
		{
			print OUT qq!$line!;
			$line_counter++;
		}
	}
	close(OUT);
	close(IN);
	
	my %time_hash =();
	my @time_array =();
	my $time_count=0;
	my $time_size=0;
	open(IN,qq!$xmltextfile_.labelpeak.basepeak.txt!);
	while($line=<IN>)
	{
		if($line=~/([^\t]+)\t([^\t]+)\t([^\t]+)\n/ and $line!~/maxpeptides	maxintensity	maxtime/)
		{
			$time_hash{$3}=$3;
		}
	}
	close(IN);
	foreach my $key (sort { $a <=> $b} keys %time_hash) 
	{
		$time_array[$time_count]=$key; 
		$time_count++;
	}
	$time_size=@time_array; 
	$lower_limit=$time_array[0]-1;
	$upper_limit=$time_array[$time_size-1]+1;
				
	if(open(OUT2,qq!>$xmltextfile.Rinfile.txt!))
	{	
		print OUT2 qq!windows(width=8, height=8)
					par(tcl=0.2)
					par(mfrow=c(1,1))
					par(mai=c(0.9,0.9,0.2,0.2))
					par(font=1)
					Datafile <- read.table("$xmltextfile_.labelled.basepeak.txt",header=TRUE, sep="\t")
		attach(Datafile)
		plot((intensity) ~ time, data=Datafile, type="l",axes=TRUE, xlab="Time", ylab="Intensity", xlim=c($lower_limit,$upper_limit), ylim=c(min(intensity),max(intensity)*2))
		Datafile2 <- read.table("$xmltextfile_.labelpeak.basepeak.txt",header=TRUE, sep="\t")
		attach(Datafile2)
		text(maxtime,(maxintensity),maxpeptides, adj = c(0,0.5),offset=3,col="firebrick", srt=90, cex=0.6)
		!;
		print OUT2 qq!savePlot(filename="$xmltextfile_.labelled.basepeak.png",type="png")!;
		close(OUT2);		
		system(qq!"C:\\R\\bin\\x64\\Rterm.exe" --no-restore --no-save < "$xmltextfile.Rinfile.txt" > "$xmltextfile.Routfile.txt" 2>&1!);
	}
}
close(LOG);