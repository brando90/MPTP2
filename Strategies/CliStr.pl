#!/usr/bin/perl -w

# ls *protok*simple *protok*_KBO *protok*_SOS| xargs grep -l Theorem | xargs grep Processed | perl -F ~/gr/MPTP2/Strategies/CliStr.pl | less

# p.leancop.cnf.protokoll_cnf_my18simple_KBO:#

# ime ./param_ils_2_3_run.rb -numRun 0 -scenariofile example_e1/scenario-e8.txt -N 200 -validN 6 -init zz34

# ls *protok*simple *protok*_KBO *protok*_SOS| xargs grep -l Theorem | xargs grep Processed | perl -e ' while(<>) { m/^([^.]*)\.(.*): *(\d+)/ or die; if((! exists($h{$1})) || ($h{$1} > $3)) { $i{$1}=$h{$1}; $j{$1}=$g{$1}; $h{$1} = $3; $g{$1} = $2; }} foreach $k (sort keys %h) { $v{$g{$k}}{$k}=$h{$k}  } foreach $p (sort keys %v) {print "\n$p:\n"; foreach $k (sort keys %{$v{$p}}) {print "$k:$h{$k}\n" if(($h{$k}>500) && ($h{$k}<30000))}}' |less

use strict;


my $gPIdir = '/home/mptp/big/ec/paramils2.3.5-source';

my $gPIexmpldir = $gPIdir . "/example_data";

my $gstratsdir = "strats";


my $gmaxstr = shift;
my $gminstrprobs = shift;

$gmaxstr = 20 unless(defined($gmaxstr));
$gminstrprobs = 8 unless(defined($gminstrprobs));

sub PrintProbStr
{
    my ($v,$min,$max) = @_;
    foreach my $p (sort keys %$v) {
	print "\n$p:\n";
	foreach my $k (sort keys %{$v->{$p}}) {
	    print "$k:$v->{$p}{$k}\n" if(($v->{$p}{$k}>=$min) && ($v->{$p}{$k}<=$max));
	}
    }
}

sub PrintProbStrFiles
{
    my ($v,$iter,$min,$max) = @_;
    foreach my $p (sort keys %$v) {
	print "\n$p:\n";
	foreach my $k (sort keys %{$v->{$p}}) {
	    print "$k:$v->{$p}{$k}\n" if(($v->{$p}{$k}>=$min) && ($v->{$p}{$k}<=$max));
	}
    }
}


sub TopStratProbs
{
    my ($maxstr,$minstrprobs) = @_;
    my %g = ();
    my %h = ();
    my %i = ();
    my %j = ();
    my %v = ();
    my %c = ();

    while (<>)
    {
	m/^([^.]*)\..*(protokoll_[^:]*).*: *(\d+)/ or die;
	if ((! exists($h{$1})) || ($h{$1} > $3))
	{
	    $i{$1}=$h{$1};
	    $j{$1}=$g{$1};
	    $h{$1} = $3;
	    $g{$1} = $2;
	}
    }

    foreach my $s (values %g) { $c{$s}++; }

    foreach my $s (keys %c) { $c{$s}=0 if( $c{$s} < $minstrprobs ); }

    my $cnt = 0;
    foreach my $s (sort {$c{$b} <=> $c{$a}} keys %c) { $cnt++; $c{$s}=0 if($cnt > $maxstr); }


    foreach my $k (sort keys %h)
    {
	$v{$g{$k}}{$k}=$h{$k} if($c{$g{$k}} > 0);
    }

    return (\%h, \%v);
}


my ($h,$v) = TopStratProbs($gmaxstr,$gminstrprobs);

PrintProbStr($v,500,30000);


