#!/usr/bin/perl -w

## $Revision: 1.5 $


=head1 NAME

TheoryLearner.pl (Script trying to solve multiple problems in large theory by learning from successes)

=head1 SYNOPSIS

TheoryLearner.pl [options] filestem

time ./TheoryLearner.pl --fileprefix='chainy_lemma1/' --filepostfix='.ren' chainy1 | tee chainy1.log

 Options:
   --fileprefix=<arg>,      -e<arg>
   --filepostfix=<arg>,     -s<arg>
   --refsbgcheat=<arg>,     -r<arg>
   --help,                  -h
   --man

=head1 OPTIONS

=over 8

=item B<<< --fileprefix=<arg>, -e<arg> >>>

Prefix saying how to create problem file names from conjecture names.
It is prepended to the conjecture name (and can contain directory part).

=item B<<< --filepostfix=<arg>, -s<arg> >>>

Postfix saying how to create problem file names from conjecture names.
It is appended to the conjecture name (typically a file extension).

=item B<<< --dofull=<arg>, -f<arg> >>>

If 1, the first pass is a max-timelimit run on full problems. If 0,
that pass is omitted, and the symbol-only pass is the first run.
Default is 1.

=item B<<< --recadvice=<arg>, -a<arg> >>>

If nonzero, the axiom advising phase is repeated this many times,
recursively using the recommended axioms to enlarge the set of symbols
for the next advising phase. Default is 0 (no recursion).


=item B<<< --refsbgcheat=<arg>, -r<arg> >>>

Tells to cheat by limiting background for problems
whose subproblems (specified in .refspec) are solved.
Useful for reproving. Default is 0 - no cheating.

=item B<<< --alwaysmizrefs=<arg>, -m<arg> >>>

Tells to always include the explicit Mizar references. This
is useful for the bushy problems, where we are reasonably sure
that the explicit Mizar references should be used in the proof,
while we are uncertain about the background formulas.
The explicit references are now recongized by matching the regexp
"^[tldes][0-9]+" (for theorems, top-level lemmas, definitions,
sublemmas, and scheme instances).

=item B<<< --help, -h >>>

Print a brief help message and exit.

=item B<<< --man >>>

Print the manual page and exit.

=back

=head1 DESCRIPTION

TODO

=head1 CONTACT

Josef Urban urban@kti.ms.mff.cuni.cz

=cut

use strict;
use Pod::Usage;
use Getopt::Long;
use IO::Socket;

my (%gsyms,$grefs,$client);
my $gsymoffset=100000; # offset at which symbol numbering starts
my %grefnr;     # Ref2Nr hash for references
my @gnrref;     # Nr2Ref array for references

my %gsymnr;   # Sym2Nr hash for symbols
my @gnrsym;   # Nr2Sym array for symbols - takes gsymoffset into account!

my %grefsyms;   # Ref2Sym hash for each reference array of its symbols
my %gspec;   # Ref2Spec hash for each reference hash of its initial references
my %gresults; # hash of results
my %gsubrefs; # contains direct lemmas for those proved by mizar_proof,
              # only if $grefsbgcheat == 0
my %gsuperrefs; # contains additions to bg inherited from direct lemmas
                # for those proved by mizar_proof, only if $grefsbgcheat == 0

my $maxthreshold = 256;
my $minthreshold = 4;
my ($gfileprefix,$gfilepostfix,$gdofull,$grecadvice,$grefsbgcheat,$galwaysmizrefs);
my ($help, $man);
my $maxtimelimit = 64;  # should be power of 4
my $mintimelimit = 1;
my $gtimelimit = $maxtimelimit;
my $gtargetsnr = 1233;


Getopt::Long::Configure ("bundling");

GetOptions('fileprefix|e=s'    => \$gfileprefix,
	   'filepostfix|s=s'    => \$gfilepostfix,
	   'dofull|f=i'    => \$gdofull,
	   'recadvice|a=i'    => \$grecadvice,
	   'refsbgcheat|r=i'    => \$grefsbgcheat,
	   'alwaysmizrefs|m=i'    => \$galwaysmizrefs,
	   'help|h'          => \$help,
	   'man'             => \$man)
    or pod2usage(2);

pod2usage(1) if($help);
pod2usage(-exitstatus => 0, -verbose => 2) if($man);

pod2usage(2) if ($#ARGV != 0);

my $filestem   = shift(@ARGV);

$gdofull = 1 unless(defined($gdofull));
$grecadvice = 0 unless(defined($grecadvice));
$grefsbgcheat = 0 unless(defined($grefsbgcheat));
$galwaysmizrefs = 0 unless(defined($galwaysmizrefs));
$gfileprefix = "" unless(defined($gfileprefix));
$gfilepostfix = "" unless(defined($gfilepostfix));


# change for verbose logging
sub LOGGING { 0 };

# print %gresults before dying if possible
local $SIG{__DIE__} = sub { DumpResults(); };

sub LoadTables
{
    my $i = 0;
    my ($ref,$sym,@syms,$psyms,$fsyms);

    %grefnr = ();
    %gsymnr = ();
    %grefsyms = ();
    @gnrsym = ();
    @gnrref = ();

    open(REFNR, "$filestem.refnr") or die "Cannot read refnr file";
    open(SYMNR, "$filestem.symnr") or die "Cannot read symnr file";
    open(REFSYMS, "$filestem.refsyms") or die "Cannot read refsyms file";

    while($_=<REFNR>) { chop; push(@gnrref, $_); $grefnr{$_} = $#gnrref;};
    while($_=<SYMNR>) { chop; push(@gnrsym, $_); $gsymnr{$_} = $gsymoffset + $i++; };
    while($_=<REFSYMS>)
    {
	chop; 
	m/^symbols\( *([a-z0-9A-Z_]+) *, *\[(.*)\] *, *\[(.*)\] *\)\./ 
	    or die "Bad symbols info: $_";
	($ref, $psyms, $fsyms) = ($1, $2, $3);
	my @psyms = split(/\,/, $psyms);
	my @fsyms = split(/\,/, $fsyms);
	my @allsyms = (@psyms, @fsyms);
	$grefsyms{$ref} = [];
	foreach $sym (@allsyms)
	{

	    $sym =~ m/^ *([^\/]+)[\/].*/ or die "Bad symbol $sym in $_";
	    push(@{$grefsyms{$ref}}, $1);
	}
    }
}

# Create the symbol and reference numbering files
# from the refsyms file. Loads these tables and the refsym table too.
# The initial refsyms file can be created from all (say bushy) problems by running:
# cat */* | GetSymbols |sort -u > all.refsyms
sub CreateTables
{
    my $i = 0;
    my ($ref,$sym,@syms,$psyms,$fsyms,%tmpsyms);

    open(REFSYMS, "$filestem.refsyms") or die "Cannot read refsyms file";
    open(REFNR, ">$filestem.refnr") or die "Cannot write refnr file";
    open(SYMNR, ">$filestem.symnr") or die "Cannot write symnr file";

    %grefnr = ();
    %gsymnr = ();
    %grefsyms = ();
    @gnrsym = ();
    @gnrref = ();

    while($_=<REFSYMS>)
    {
	chop; 
	m/^symbols\( *([a-z0-9A-Z_]+) *, *\[(.*)\] *, *\[(.*)\] *\)\./ 
	    or die "Bad symbols info: $_";
	($ref, $psyms, $fsyms) = ($1, $2, $3);
	my @psyms = split(/\,/, $psyms);
	my @fsyms = split(/\,/, $fsyms);
	my @allsyms = (@psyms, @fsyms);
	die "Duplicate reference $ref in $_" if exists $grefnr{$ref};
	$grefsyms{$ref} = [];
	push(@gnrref, $ref);
	$grefnr{$ref} = $#gnrref;
	print REFNR "$ref\n";
	foreach $sym (@allsyms)
	{
	    $sym =~ m/^ *([^\/]+)[\/].*/ or die "Bad symbol $sym in $_";
	    $tmpsyms{$1} = ();
	    push(@{$grefsyms{$ref}}, $1);
	}
    }
    close REFNR;
    foreach $sym (keys %tmpsyms)
    {
	print SYMNR "$sym\n";
	push(@gnrsym, $sym);
	$gsymnr{$sym} = $gsymoffset + $i++;
    }
    close SYMNR;
    close REFSYMS;
    $gtargetsnr = $#gnrref;
}

# CreateTables;
# die "finished";
#LoadTables();

sub TestTables
{
 foreach $_ (keys %grefsyms) 
 { print "$_:@{$grefsyms{$_}}\n";}
}

# fields in the %gresults entries
sub res_STATUS  ()  { 0 }
sub res_REFNR   ()  { 1 }
sub res_CPULIM  ()  { 2 }
sub res_REFS    ()  { 3 }
sub res_NEEDED  ()  { 4 }  # only for res_STATUS == szs_THEOREM

# possible SZS statuses
sub szs_INIT        ()  { 'Initial' } # system was not run on the problem yet
sub szs_UNKNOWN     ()  { 'Unknown' } # used when system dies
sub szs_THEOREM     ()  { 'Theorem' }
sub szs_COUNTERSAT  ()  { 'CounterSatisfiable' }
sub szs_RESOUT      ()  { 'ResourceOut' }
sub szs_GAVEUP      ()  { 'GaveUp' }   # system exited before the time limit for unknown reason



# Following command will create all initial unpruned problem specifications,
# in format spec(name,references), e.g.:
# spec(t119_zfmisc_1,[reflexivity_r1_tarski,t118_zfmisc_1,rc1_xboole_0,dt_k2_zfmisc_1,t1_xboole_1,rc2_xboole_0]).
# and print the into file foo.specs
# for i in `ls */*`; do perl -e   'while(<>) { if(m/^ *fof\( *([^, ]+) *,(.*)/) { ($nm,$rest)=($1,$2); if($rest=~m/^ *conjecture/) {$conjecture=$nm;} else {$h{$nm}=();}}} print "spec($conjecture,[" . join(",", keys %h) . "]).\n";' $i; done >foo.specs

# loads also %gsubrefs and %gsuperrefs if $grefsbgcheat == 1
sub LoadSpecs
{
#    LoadTables();
    %gspec = ();
    %gresults = ();
    %gsubrefs = ();
    %gsuperrefs = ();
    open(SPECS, "$filestem.specs") or die "Cannot read specs file";
    while (<SPECS>) {
	my ($ref,$refs,$ref1);

	m/^spec\( *([a-z0-9A-Z_]+) *, *\[(.*)\] *\)\./ 
	    or die "Bad spec info: $_";

	($ref, $refs) = ($1, $2);
	my @refs = split(/\,/, $refs);
	$gspec{$ref} = {};
	$gresults{$ref} = [];
	my $new_spec = [szs_INIT, $#refs, -1, [@refs], []];
	push(@{$gresults{$ref}}, $new_spec);
	# also some sanity checking
	foreach $ref1 (@refs)
	{
	    exists $grefnr{$ref} or die "Unknown reference $ref in $_";
	    ${$gspec{$ref}}{$ref1} = ();
	}
    }
    close SPECS;
    if ($grefsbgcheat == 1)
    {
	open(SUBREFS, "$filestem.subrefs") or die "Cannot read subrefs file";
	while (<SUBREFS>) {
	    my ($ref,$subrefs,$superrefs,$ref1);

	    m/^refspec\( *([a-z0-9A-Z_]+) *, *\[(.*)\] *, *\[(.*)\] *\)\./ 
		or die "Bad refspec info: $_";

	    ($ref, $subrefs, $superrefs) = ($1, $2, $3);
	    my @subrefs = split(/\, */, $subrefs);
	    my @superrefs = split(/\, */, $superrefs);
	    $gsubrefs{$ref} = {};
	    $gsuperrefs{$ref} = {};
	    # also some sanity checking
	    foreach $ref1 (@subrefs) {
		exists $grefnr{$ref} or die "Unknown reference $ref in $_";
		${$gsubrefs{$ref}}{$ref1} = ();
	    }
	    # also some sanity checking
	    foreach $ref1 (@superrefs) {
		exists $grefnr{$ref} or die "Unknown reference $ref in $_";
		${$gsuperrefs{$ref}}{$ref1} = ();
	    }
	}
    }
}

sub TestSpecs
{
    foreach $_ (keys %gspec) 
    {
	my @refs = keys %{$gspec{$_}};
	print "$_:@refs\n";
    }
}
#LoadSpecs();
#TestSpecs();
#die "finished";

# The initial .to_prove_0 file is just the list of all conjectures in all problems, i.e.:
# cat */*| grep "^ *fof( *[^, ]* *, *conjecture" | sed -e 's/^ *fof( *\([^, ]\+\) *,.*/\1/' > foo.to_prove_0
#
# further iterations are obtained by finding out which conjectures have not been proved yet


# snow is run on the resulting .test_$iter file e.g. this way:
# snow -test -I lear1.test_0 -F lear1.net_0  -L 300 -o allboth  -B :0-1234 
# (it limits the output to 300 most relevant references)

# Print the data for problems on which you want to have advice by the
# machine learner. This takes the file of conjecture names ( .to_prove_$iter ) as input,
# translates the symbols contained in them to numbers, and prints them as testing data to
# file .test_$iter . The number of the conjecture is printed too (it should not influence 
# the testing), in order to make the snow output labeled (better for parsing).
sub PrintTesting
{
    my ($iter) = @_;
    LoadTables();
    open(TO_PROVE, "$filestem.to_prove_$iter") or die "Cannot read to_prove_$iter file";
    open(TEST, ">$filestem.test_$iter") or die "Cannot write test_$iter file";
    while (<TO_PROVE>) {
	chop;
	my $ref = $_;
	exists $grefsyms{$ref} or die "Unknown reference $ref";
	my @syms = @{$grefsyms{$ref}};
	my @syms_nrs   = map { $gsymnr{$_} if(exists($gsymnr{$_})) } @syms;
	push(@syms_nrs, $grefnr{$ref});
	my $testing_exmpl = join(",", @syms_nrs);
	print TEST "$testing_exmpl:\n";
    }
    close TO_PROVE;
    close TEST;
}

# also now prints the to_prove_$iter files, which is used as a check
# for SelectRelevantFromSpecs
# the conjecture is printed to become a check for SelectRelevantFromSpecs
sub PrintTestingFromArray
{
    my ($iter,$conjs) = @_;
    my $ref;
    my $iter1 = ($grecadvice > 0) ? $iter . "_" . $grecadvice : $iter;
    open(TO_PROVE,">$filestem.to_prove_$iter") or die "Cannot write to_prove_$iter file";
    open(TEST, ">$filestem.test_$iter1") or die "Cannot write test_$iter1 file";
    foreach $ref (@$conjs) {
	exists $grefsyms{$ref} or die "Unknown reference $ref";
	my @syms = @{$grefsyms{$ref}};
	my @syms_nrs   = map { $gsymnr{$_} if(exists($gsymnr{$_})) } @syms;
	push(@syms_nrs, $grefnr{$ref});
	my $testing_exmpl = join(",", @syms_nrs);
	print TEST "$testing_exmpl:\n";
	print TO_PROVE "$ref\n";
    }
    close TEST;
    close TO_PROVE;
}

# gets array of specs consisting of conjecture and some axioms
# instead of just a conjecture
# the conjecture is printed to become a check for SelectRelevantFromSpecs
sub PrintTestingFromArrArray
{
    my ($iter,$specs) = @_;
    my $spec1;
    open(TEST, ">$filestem.test_$iter") or die "Cannot write test_$iter file";
    foreach $spec1 (@$specs)
    {
	my @spec = @$spec1;
	my %symsh = ();
	my $ref;
	foreach $ref (@spec)
	{
	    exists $grefsyms{$ref} or die "Unknown reference $ref";
	    @symsh{ @{$grefsyms{$ref}} } = ();
	}
	my @syms_nrs   = map { $gsymnr{$_} if(exists($gsymnr{$_})) } (keys %symsh);
	push(@syms_nrs, $grefnr{$spec[0]});
	my $testing_exmpl = join(",", @syms_nrs);
	print TEST "$testing_exmpl:\n";
    }
    close TEST;
}



sub DumpResults
{
    my ($iter) = @_;
    my ($conj,$result);
    $iter = "" unless defined $iter;
    open(RESULTS,">$filestem.results_$iter");
    foreach $conj (sort keys %gresults)
    {
	print RESULTS "results($conj,[";
	my $comma = 0;
	foreach $result (@{$gresults{$conj}})
	{
	    my $ref_str = join(",", @{$result->[res_REFS]});
	    my $needed_str = join(",", @{$result->[res_NEEDED]});
	    if($comma==1) { print RESULTS ",";} else { $comma++; }
	    print RESULTS "res($result->[res_STATUS],$result->[res_REFNR],$result->[res_CPULIM],[$ref_str],[$needed_str])";
	}
	print RESULTS "]).\n";
    }
    close RESULTS;
}


# load %gresults from file; if $load_proved_by == 1, load also the needed slot
# in %gresults from the proved_by files - in that case we do not expect that slot
# to be in the results file
sub LoadResults
{
    my ($filename, $load_proved_by) = @_;
    open(RESULTS,$filename) or die "$filename unreadable";
    %gresults = ();
    while($_=<RESULTS>)
    {
	chop;
	m/^results\(([^,]+),\[(.*)\]\)[.]$/ or die "Bad entry in results file: $filename: $_";
	my ($conj,$results_str) = ($1, $2);
#	print "$results_str\n";
	$gresults{$conj} = [];
	if ($load_proved_by == 0)
	{
	    while ($results_str =~ m/res\(([^,]+),([0-9]+),([0-9]+),\[([^\]]*)\],\[([^\]]*)\]\)/g)
	    {
		my @spec_refs = split(/\,/, $4);
		my @needed_refs = split(/\,/, $5);
		my $new_res = [$1, $2, $3, [@spec_refs], [@needed_refs] ];
		push( @{$gresults{$conj}}, $new_res);
	    }
	}
	else
	{
	    while ($results_str =~ m/res\(([^,]+),([0-9]+),([0-9]+),\[([^\]]*)\]\)/g)
	    {
		my @spec_refs = split(/\,/, $4);
		my $new_res = [$1, $2, $3, [@spec_refs], [] ];
		push( @{$gresults{$conj}}, $new_res);
	    }
	}
    }
    close RESULTS;

    if ($load_proved_by == 1)
    {
	`cat $filestem.proved_by_* > $filestem.all_proved_by`;
	open(PROVED_BY,"$filestem.all_proved_by");
	while($_=<PROVED_BY>)
	{
	    chop;
	    m/^proved_by\(([^,]+),\[([^\]]*)\]\)\./ or die "Bad proved_by entry: $_";
	    my ($conj,$needed_str) = ($1, $2);
	    (exists $gresults{$conj}) or die "Conjecture not in $filename: $conj in $_";
	    my @conj_entries = @{$gresults{$conj}};
	    my @needed_refs = split(/\,/, $needed_str);
	    ($conj_entries[$#conj_entries]->[res_STATUS] eq szs_THEOREM) or die "Bad last results entry for $conj";
	    $conj_entries[$#conj_entries]->[res_NEEDED] = [ @needed_refs ];
	}
	close PROVED_BY;
    }
}

# testing:
# LoadResults("bl3.results2",0);
# DumpResults();
# exit;

# First field in $spec1 is assumed to be the conjecture here.
# This is done only for unproved entries in %gresults; %gresults
# gets updated with entries with 'Unknown' SZSStatus, and -1 timelimit;
# for each $conj, $gresults{$conj} is an array of arrays
# [SZSStatus,NrOfRefs,TimeLimit,Refs]
# returns 0 if this spec was irrelevant (i.e. already tried before and noted in %gresults),
# and nothing was done, otherwise 1;
# Note that entries in %gspec also contain the conjecture.
# @$spec1 and @$reserve1 are guaranteed to be a subset of @allrefs here.
# ##TODO: improve for lemmatizing
sub HandleSpec
{
    my ($iter, $file_prefix, $file_postfix, $spec1, $reserve1) = @_;
    my @spec = @$spec1;
    my @reserve = @$reserve1;
    my $conjecture = $spec[0];
    my @all_refs = keys %{$gspec{$conjecture}};

    my $result;
    my $subsumed = 0;
    my $i = 0;

    # for each previous result, check that it does not subsume the
    # new specification; this is now achieved either by being subset of
    # CounterSatisfiable spec, or being equal to any previous spec.
    # If subsumed, try to add one reference from @reserve to @spec and check again -
    # but do this only if $gtimelimit == $mintimelimit not to waste CPU on randomness
    my @results = @{$gresults{$conjecture}};
    while ($i <= $#results)
    {
	$result = $results[$i];
	$i++;

	if((0 == $subsumed) &&
	   ((($#spec <= $result->[res_REFNR]) && (szs_COUNTERSAT eq $result->[res_STATUS]))
	    || ($#spec == $result->[res_REFNR])))
	{
	    my %cmp_refs = ();
	    @cmp_refs{ @spec } = ();            # insert the new refs
	    delete @cmp_refs{ @{$result->[res_REFS]} };   # delete the old ones
	    my @remaining = keys %cmp_refs;
	    if ((-1 == $#remaining) &&
		(($gtimelimit <= $result->[res_CPULIM]) ||
		 (szs_COUNTERSAT eq $result->[res_STATUS]) ||
		 (szs_UNKNOWN eq $result->[res_STATUS])))  # the last one means that systems died on the same input
	    {
		if (($#reserve >= 0) && ($gtimelimit == $mintimelimit))
		{
		    my $added = shift @reserve;
		    push(@spec, $added);
		    $i = 0;
		}
		else { $subsumed = 1; }
	    }
	}
    }

    if (0 == $subsumed)
    {
	my $new_spec = [szs_INIT, $#spec, -1, [@spec], [] ];
	push(@{$gresults{$conjecture}}, $new_spec);
	my $new_refs = join(",", @spec);
	print SPEC "spec($conjecture,[$new_refs]).\n";
	PrintPruned($iter, $file_prefix, $file_postfix, \@spec);
	return 1;
    }
    else { return 0; }
}

sub PrintPruned
{
    my ($iter, $file_prefix, $file_postfix, $spec) = @_;

    my $conjecture = $spec->[0];
    my $old_file = $file_prefix . $conjecture . $file_postfix;
    (-r $old_file) or die "$old_file not readable!";
    my $regexp = '"^fof( *\(' . join('\|',@{$spec}) . '\) *,"';
    `grep $regexp $old_file > $old_file.s_$iter`;

}

# writes a new spec_$iter file, created by testing the to_prove_$iter file
# on net_$iter net
# Note that @spec always contains its conjecture.
# I/O: prints .s_$iter file with spec for each active conjecture;
#      RunProblems() uses that
# Modifies: %gresults
# Returns: list of conjectures to try
sub SelectRelevantFromSpecs
{
    my ($iter, $threshold, $file_prefix, $file_postfix, $recurse) = @_;

#    LoadSpecs(); # calls LoadTables too

    my @to_prove = (); # for checking the SNoW output
    open(TO_PROVE, "$filestem.to_prove_$iter") or die "Cannot read to_prove_$iter file";
    while($_=<TO_PROVE>) { chop; push(@to_prove, $_); }
    close TO_PROVE;

    my (@spec, @reserve, $wanted, $check, $act);
    undef $check;
    undef $wanted;
    @spec = ();
    @reserve = ();
    my @active = ();
    my $do_example = 0;
    my $wantednr = $gtargetsnr;
    my @specs = ();

    ## becomes 0 if no recadvice
    $recurse = $grecadvice unless(defined($recurse));

    if($recurse == 0)
    {
	open(SPEC, ">$filestem.spec_$iter") or die "Cannot write spec_$iter file";
    }

    my $iter1 = ($grecadvice > 0) ? $iter . "_" . $recurse : $iter;
    my $snow_pid = open(SOUT,"bin/snow -test -I $filestem.test_$iter1 -F $filestem.net_$iter -L $wantednr -o allboth -B :0-$gtargetsnr|tee $filestem.eval_$iter1|") 
	or die("Cannot start snow: $iter1");

    while ($_=<SOUT>)
    {
        if (/^Example/)        # Start entry for a new example
        {
	    # print the previous entry
	    if ($do_example == 1)
	    {

		if($recurse > 0)
		{
		    my @spec2 = @spec;
		    push(@specs, \@spec2);
#		    PrintTestingFromArrArray($iter . "_" . ($recurse - 1), \@spec);
		}
		else
		{
		    $act = HandleSpec($iter, $file_prefix, $file_postfix, \@spec, \@reserve);
		    push(@active, $spec[0]) if ($act == 1);
		}
	    }

	    @spec = ();
	    @reserve = ();
	    $do_example = 1;

            /^Example.*: *([0-9]+) */ or die "Bad Example $_ in iter:$iter";
            ($wanted, $check) = ($1, shift @to_prove);
#	    print "$check\n";
	    (exists $gnrref[$wanted]) or die "Unknown reference $wanted";
	    ($wanted == $grefnr{$check}) or
		die "Not in sync with .to_prove_$iter: $wanted,$gnrref[$wanted],$grefnr{$check},$check";
	    push(@spec, $check);
        }
	if (/^([0-9]+):/)
        {
	    # Push eligible references - those which are in the initial spec

	    my $refnr = $1;
	    exists $gnrref[$refnr] or die "Parse error - undefined refnr: $_";
	    my $ref1 = $gnrref[$refnr];
	    defined($check) or die "Parse error - undefined example: $_";
	    exists $gspec{$check} or die "Parse error: $check not in gspec: $_";
	    if ((exists ${$gspec{$check}}{$ref1}) && !($refnr == $grefnr{$check}))
	    {
		if (($#spec < $threshold) ||
		    (($galwaysmizrefs == 1) && ($ref1 =~ m/^[tldes][0-9]+/)))
		{
		    push(@spec, $ref1);
		}
		else { push(@reserve, $ref1); }
	    }
	}
    }

    close(SOUT);

    # print the last entry
    if ($do_example == 1)
    {
	if($recurse > 0)
	{
	    push(@specs, \@spec);
	    PrintTestingFromArrArray($iter . "_" . ($recurse - 1), \@specs);
	}
	else
	{
	    $act = HandleSpec($iter, $file_prefix, $file_postfix, \@spec, \@reserve);
	    push(@active, $spec[0]) if ($act == 1);
	}
    }

    die "Some entries unhandled in .to_prove_$iter: @to_prove" if ($#to_prove >= 0);
    if($recurse > 0)
    {
	return SelectRelevantFromSpecs($iter,$threshold, $file_prefix, $file_postfix, $recurse - 1);
    }
    else
    {
	close(SPEC);
	`gzip $filestem.eval_$iter*`;
	return \@active;
    }
}

# SelectRelevantFromSpecs(0,30,"bushy/",".ren");
# die "finished";


# the algorithm:

# We now assume that all problems are in one flat directory (e.g. "chainy"), and
# that they can be adressed using the name of the conjecture ($conj) and
# common $file_prefix and $file_postfix (so the name is $file_prefix . $conj . $file_postfix).
# There should be no other files in the directory in the beginning.


# 1. create initial specification info (.specs) from the problems by calling
# for i in `ls $file_prefix*$file_postfix`; do perl -e   'while(<>) { if(m/^ *fof\( *([^, ]+) *,(.*)/) { ($nm,$rest)=($1,$2); if($rest=~m/^ *conjecture/) {$conjecture=$nm;} else {$h{$nm}=();}}} print "spec($conjecture,[" . join(",", keys %h) . "]).\n";' $i; done > $filestem.specs


# 2. create the .refsyms table telling for each reference its symbols by calling:
# cat $file_prefix*$file_postfix | GetSymbols |sort -u > $filestem.refsyms

# 3. create the numbering files for references and symbols by calling CreateTables

# 4. create the initial .proved_by_0 table (telling that each reference can be proved by itself)
#    from the .refnr file by running:
# sed -e 's/\(.*\)/proved_by(\1,[\1])./' <foo.refnr > foo.proved_by_0

# 5. create the initial SNoW training file .train_0 from the .proved_by_0 file by calling
# PrintTraining(0)

# 6. train SNoW on the initial file (creating the first net file .net_0),
# with references being the targets (i.e. the range is usually 0 - highest reference number (`wc -l foo.refnr`),
#  e,g, this way:
# snow -train -I foo.train_0 -F foo.net_0  -B :0-1234

# 7. create the initial file of conjectures that should be proved (.to_prove_0) from all conjectures in all
# problems (it now holds that every problem contains exactly one conjecture):
# cat */*| grep "^ *fof( *[^, ]* *, *conjecture" | sed -e 's/^ *fof( *\([^, ]\+\) *,.*/\1/' > foo.to_prove_0

# 8. create the initial test file (.test_0) from the initial conjecures to be proved (.to_prove_0);
# to get SNoW hints on them using .net_0: PrintTesting(0);

# 9. evaluate the initial .specs file with the initial net (.net_0), and an initial
# cut-off threshold, on the initial test file (.test_0); say we want only 30 formulas in each file -
# if this is a bushy task, we know that only background formulas should be cut off, but ignore it for now);
# this will create the specs_0 file, and file .s_0 for each prune-able problem:
# snow -test -I lear1.test_0 -F lear1.net_0  -L 300 -o allboth  -B :0-1234 | SelectRelevantFromSpecs(0,30) > lear1.specs_0

# 10. run provers on initial files and .s_0 files to get a new version of the .proved_by table ... probably preceded
#     by creation of a results_0 table, which will keep more info used for avoiding repeating
#     trial of problems; repetitions that should be avoided:
#    - pruned problem was solved
#    - pruned problem was CounterSatisfiable, and newly pruned version is its subset
#    - pruned problem was too hard (timeout), and newly pruned version is 
#        equal to it (note that we should allow supersets, since the previous pruning 
#        might be too drastic, but still too difficult to detect CounterSatisfiability)
#
#  Note that we might also store interesting lemmas as Stephan Schulz's lemmatify does;
#  We might also develop lemmas a la Petr Pudlak, and name them and add them to the learning


# Learn from the .alltrain_$iter file, which was created by PrintTrainingFromHash
sub Learn
{
    my ($iter) = @_;
    my $next_iter = 1 + $iter;
    print "LEARNING:$iter\n";
    `bin/snow -train -I $filestem.alltrain_$iter -F $filestem.net_$next_iter  -B :0-$gtargetsnr`;
}

# Run prover(s) on problems "$file_prefix$conj$file_postfix.s_$iter".
# Collect the result statuses into %gresults, and if proof was found,
# Collect the axioms used for each proved conjecture to %proved_by and return it.
# Status output is also saved to $file.out, and (possible) proof to $file.out1,
# the proved_by info is logged to proved_by_$iter.
# $spass tells to run SPASS if E fails.
# We try to "exit nicely from here": $gtimelimit is re-set to $mintimelimit whenever a theorem is proved
# - this can cause redundant entries in %gresults - this happens unless $keep_cpu_limit <> 1, which means
# that we are running with high timelimit problems (e.g. when cheating)
sub RunProblems
{
    my ($iter, $file_prefix, $file_postfix, $conjs, $spass, $keep_cpu_limit) = @_;
    my ($conj,%proved_by,$status,$spass_status,%nonconj_refs);
    %proved_by = ();

    open(PROVED_BY,">$filestem.proved_by_$iter");
    foreach $conj (@$conjs)
    {
	my $file = $file_prefix . $conj . $file_postfix . ".s_" . $iter;
	print "$conj: ";
	my $status_line = `bin/eprover -tAuto -xAuto --tstp-format -s --cpu-limit=$gtimelimit $file 2>$file.err | grep "SZS status" |tee $file.out`;

	if ($status_line=~m/.*SZS status *: *(.*)/)
	{
	    $status = $1;
	}
	else
	{
	    print "Bad status line, assuming szs_UNKNOWN: $file: $status_line";
	    $status = szs_UNKNOWN;
	}
	print "E: $status";
	my @conj_entries = @{$gresults{$conj}};
	($conj_entries[$#conj_entries]->[res_STATUS] eq szs_INIT) or die "Bad initial results entry for $conj";
	$conj_entries[$#conj_entries]->[res_CPULIM] = $gtimelimit;
	if ($status eq szs_THEOREM)
	{
	    ($gtimelimit = $mintimelimit) if ($keep_cpu_limit == 0);
	    my $eproof_pid = open(EP,"bin/eproof -tAuto -xAuto --tstp-format $file | tee $file.out1| grep file|")
		or die("Cannot start eproof");
	    $proved_by{$conj} = [];
	    while ($_=<EP>)
	    {
		m/.*,file\([^\),]+, *([a-z0-9A-Z_]+) *\)/ or die "bad proof line: $file: $_";
		my $ref = $1;
		exists $grefnr{$ref} or die "Unknown reference $ref in $file: $_";
		push( @{$proved_by{$conj}}, $ref);
	    }
	    my $conj_refs = join(",", @{$proved_by{$conj}});
	    print PROVED_BY "proved_by($conj,[$conj_refs]).\n";
	    %nonconj_refs = ();
	    @nonconj_refs{ @{$proved_by{$conj}} } = ();
	    delete $nonconj_refs{ $conj };
	    $conj_entries[$#conj_entries]->[res_NEEDED] = [ keys %nonconj_refs ];
	}
	if (($spass == 1) && 
	    (($status eq szs_RESOUT) || ($status eq szs_GAVEUP) || ($status eq szs_UNKNOWN)))
	{
	    my $spass_status_line =
		`bin/tptp4X -x -f dfg $file | bin/SPASS -Stdin -PGiven=0 -PProblem=0 -TimeLimit=$gtimelimit | grep "SPASS beiseite"| tee $file.outdfg`;

	    if ($spass_status_line=~m/.*SPASS beiseite *: *([^.]+)[.]/)
	    {
		$spass_status = $1;
	    }
	    else
	    {
		print "Bad SPASS status line, assuming szs_UNKNOWN: $file: $spass_status_line";
		$spass_status = szs_UNKNOWN;
	    }

	    if ($spass_status=~m/Proof found/)
	    {
		$spass_status = szs_THEOREM;
		$status= szs_THEOREM;
		($gtimelimit = $mintimelimit) if ($keep_cpu_limit == 0);
		my $spass_formulae_line = `bin/tptp4X -x -f dfg $file |bin/SPASS -Stdin -PGiven=0 -PProblem=0 -DocProof | tee $file.outdfg1| grep "Formulae used in the proof"`;
		($spass_formulae_line=~m/Formulae used in the proof *: *(.*) */) 
		    or die "Bad SPASS Formulae line: $file: $spass_formulae_line";
		my @refs = split(/ +/, $1);
		my $ref;
		foreach $ref (@refs)
		{
		    exists $grefnr{$ref} or die "Unknown reference $ref in $file.outdfg1: $ref";
		}
		$proved_by{$conj} = [@refs];
		my $conj_refs = join(",", @{$proved_by{$conj}});
		print PROVED_BY "proved_by($conj,[$conj_refs]).\n";
		%nonconj_refs = ();
		@nonconj_refs{ @{$proved_by{$conj}} } = ();
		delete $nonconj_refs{ $conj };
		$conj_entries[$#conj_entries]->[res_NEEDED] = [ keys %nonconj_refs ];
	    }
	    elsif ($spass_status=~m/Completion found/)
	    {
		$spass_status = szs_COUNTERSAT;
		$status= szs_COUNTERSAT;
	    }
	    elsif ($spass_status=~m/Ran out/)
	    {
		$spass_status = szs_RESOUT;
		$status= szs_RESOUT;
	    }
	    print ", SPASS: $spass_status";
	}
	print "\n";
	$conj_entries[$#conj_entries]->[res_STATUS] = $status;
    }
    close(PROVED_BY);
    DumpResults($iter);
    return \%proved_by;
}

sub Iterate
{
    my ($file_prefix, $file_postfix) = @_;
    my ($conj,$i,@tmp_conjs,$to_solve);
    my %conjs_todo = ();
    my $threshold = $maxthreshold;

    # create the initial specs file, copy each file to $file.s_0
    open(INISPECS,">$filestem.specs");
    foreach $i (`ls $file_prefix*$file_postfix`)
    {
	$conj = "";
	my %h = ();
	open(PROBLEM,$i);
	while($_=<PROBLEM>)
	{
	    if(m/^ *fof\( *([^, ]+) *,(.*)/)
	    {
		my ($nm,$rest)=($1,$2);
		if ($rest=~m/^ *conjecture/)
		{
		    $conj=$nm;
		} else {$h{$nm}=();}
	    }
	}
	close(PROBLEM);
	print INISPECS "spec($conj,[" . join(",", keys %h) . "]).\n";
	chop $i;
	`cp  $i  $i.s_0`;
#	system(cp,($i, "$i.s_0"));
    }
    close(INISPECS);

    # create the refsyms file
    `cat $file_prefix*$file_postfix | sort -u | bin/GetSymbols |sort -u > $filestem.refsyms`;

    # create the refnr and symnr files, load these tables and the refsyms table
    CreateTables();

    # create the initial .proved_by_0 table (telling that each reference can be proved by itself)
    # it gets overwritten by the first RunProblems(), so cat-ing all proved_by_* files
    # together while running still gives all solved problems
    open(PROVED_BY_0,">$filestem.proved_by_0");
    foreach $i (keys %grefnr) { print PROVED_BY_0 "proved_by($i,[$i]).\n" }
#    `sed -e 's/\(.*\)/proved_by(\1,[\1])./' <$filestem.refnr > $filestem.proved_by_0`;
    close(PROVED_BY_0);

    # print the $filestem.train_0 file from .proved_by_0, train on it
    PrintTraining(0);
    print "trained 0\n";
    # die "";
    `bin/snow -train -I $filestem.train_0 -F $filestem.net_1  -B :0-$gtargetsnr`;

    `cat $file_prefix*.refspec > $filestem.subrefs` if ($grefsbgcheat == 1);
    LoadSpecs();   # initialises %gspec and %gresults
    @conjs_todo{ keys %gspec }  = (); # initialize with all conjectures

    @tmp_conjs = sort keys %conjs_todo;


    # creates the $proved_by_1 hash table, and creates initial .out,out1 files;
    # modifies $gresults! - need to initialize first
    if($gdofull == 1)
    {
	print "THRESHOLD: 0\nTIMELIMIT: $gtimelimit\n";
	my $proved_by_1 = RunProblems(0,$file_prefix, $file_postfix,\@tmp_conjs,1,1);
	delete @conjs_todo{ keys %{$proved_by_1}}; # delete the proved ones
	@tmp_conjs = sort keys %conjs_todo;
	PrintTrainingFromHash(1,$proved_by_1);
    }

    $gtimelimit = $mintimelimit;


    PrintTestingFromArray(1, \@tmp_conjs);    # write testing file for still unproved

    $to_solve = SelectRelevantFromSpecs(1,$threshold, $file_prefix, $file_postfix); # write spec_1 file and .s_1 input files

    print "SYMBOL ONLY PASS\n";
    print "THRESHOLD: $threshold\nTIMELIMIT: $gtimelimit\n";
    my $proved_by_2 = RunProblems(1,$file_prefix, $file_postfix,$to_solve,1,0);  # creates initial .s_1.out files - omits solved in .proved_by_1
    delete @conjs_todo{ keys %{$proved_by_2}}; # delete the proved ones

    @tmp_conjs = sort keys %conjs_todo;
    PrintTestingFromArray(3,\@tmp_conjs);


    PrintTrainingFromHash(2,$proved_by_2);
    `cat $filestem.train_* > $filestem.alltrain_2`;
    Learn(2);

    $to_solve = SelectRelevantFromSpecs(3,$threshold, $file_prefix, $file_postfix);

    my $iter = 3;

    while ($iter < 1000)
    {
	my $proved_by = RunProblems($iter,$file_prefix, $file_postfix,$to_solve,1,0);
	my @newly_proved = keys %$proved_by;
	# we need a better variating policy here
	if ($#newly_proved == -1)
	{
	    if ($threshold < $maxthreshold) {
		$threshold = $threshold * 2;
		print "THRESHOLD: $threshold\n";
	    }
	    else
	    {
		if ($gtimelimit < $maxtimelimit)
		{
		    $gtimelimit = 4 * $gtimelimit;
		    $threshold = 2 * $minthreshold; # if timelimit is nonminimal, start with bigger threshold
		    print "THRESHOLD: $threshold\nTIMELIMIT: $gtimelimit\n";
		}
		else
		{
		    DumpResults();
		    die "reached maximum threshold: $threshold, and timelmit: $gtimelimit";
		}
	    }
	}
	else # when we learned something new, we restart with $minthreshold and $mintimelimit
	{

	    print "SOLVED: 1+$#newly_proved\n";

	    delete @conjs_todo{ @newly_proved};
	    @tmp_conjs = sort keys %conjs_todo;


	    PrintTrainingFromHash($iter,$proved_by);

	    if ($grefsbgcheat == 1) ## check if we can cheat some bg
	    {
		# this finds all cheatable at once in a fixpoint way - 
		# so there is no need to repeat it here;
		# note that the .train_$iter_cheat_ok and .train_$iter_cheat_fail 
		# files are created too, and
		# .proved_by_$iter_cheat_fail file written with the guys that could not
		# be proved, %gresults is cheated too, to keep info about needed refs for
		# further cheating, but for the loop running properly it is enough
		# to forge just %conjs_todo
		my $cheat_specs = GetCheatableSpecs($iter, \@tmp_conjs, $file_prefix, $file_postfix);
		my @cheated_conjs = keys %{$cheat_specs};
		if ( $#cheated_conjs >= 0)
		{
		    $gtimelimit = $maxtimelimit;
		    print "FOUND CHEATABLE: 1+$#cheated_conjs:\nTIMELIMIT: $gtimelimit\n";

		    $proved_by = RunProblems($iter . "_cheat",$file_prefix, $file_postfix,\@cheated_conjs,1,1);

		    PrintTrainingFromHash($iter . "_cheat_ok",$proved_by);


		    @newly_proved = keys %$proved_by;

		    print "SOLVED WITH CHEATING: 1+$#newly_proved\n";

		    delete $cheat_specs->{ @newly_proved };

		    @newly_proved = keys %$cheat_specs;

		    PrintTrainingFromHash($iter . "_cheat_fail",$cheat_specs);

		    open(PROVED_BY,">$filestem.proved_by_$iter" . "_cheat_fail");
		    foreach $conj (sort keys %$cheat_specs)
		    {
			my $conj_refs = join(",", @{$cheat_specs->{$conj}});
			print PROVED_BY "proved_by($conj,[$conj_refs]).\n";
			my @conj_entries = @{$gresults{$conj}};
			$conj_entries[$#conj_entries]->[res_STATUS] = szs_THEOREM;
			$conj_entries[$#conj_entries]->[res_CPULIM] = $gtimelimit;

			my %nonconj_refs = ();
			@nonconj_refs{ @{ $conj_entries[$#conj_entries]->[res_REFS] } } = ();
			delete $nonconj_refs{ $conj };
			$conj_entries[$#conj_entries]->[res_NEEDED] = [ keys %nonconj_refs ];
		    }
		    close(PROVED_BY);

		    delete @conjs_todo{ @newly_proved};
		    @tmp_conjs = sort keys %conjs_todo;

		    print "CHEATED BUT UNSOLVED: 1+$#newly_proved\n";
		}
	    }

	    $threshold = $minthreshold;
	    $gtimelimit = $mintimelimit;
	    print "THRESHOLD: $threshold\nTIMELIMIT: $gtimelimit\n";
	}

	`cat $filestem.train_* > $filestem.alltrain_$iter`;
	Learn($iter);
	$iter++;
	PrintTestingFromArray($iter,\@tmp_conjs);
	$to_solve = SelectRelevantFromSpecs($iter,$threshold, $file_prefix, $file_postfix);
    }
    DumpResults();
}

Iterate($gfileprefix,$gfilepostfix);


# only create cheatable specs after a run:
# LoadTables();
# $grefsbgcheat = 1;
# LoadSpecs();   # initialises %gspec and %gresults
# LoadResults("bl3.results2",0);
# GetCheatableSpecs(0, $gfileprefix, $gfilepostfix);
# exit;

# Return the hash of cheatable conjectures with their cheated needed references
# (so the same output as from RunProblems() ). 
# the assumption is that everything outside @$conjs is already solved.
# Also sets another %gresults record with szs_INIT for cheatable.
sub GetCheatableSpecs
{
  my ($iter, $file_prefix, $file_postfix, $conjs) = @_;

  my %cheatable_unpr = ();
  my %subr_count = ();
  my ($conj,$ref1,$pr_conj,$unpr_cheat,%all_proved);
  my %cheat_specs = ();

  my $cheat_log = "/dev/null";

  my @cheatable = keys %gsubrefs;

  if(defined $conjs)
  {
      @all_proved{ keys %gspec }  = ();
      delete @all_proved{ @$conjs };
  }
  else # conjectures are all unproved entries in %gresults
  {
      %all_proved = ();
      foreach $conj (keys %gresults)
      {
	  my @conj_entries = @{$gresults{$conj}};
	  if($conj_entries[$#conj_entries]->[res_STATUS] eq szs_THEOREM)
	  {
	      $all_proved{$conj} = ();
	  }
      }
  }

  my @proved_conjs = keys %all_proved;
  my @old_proved = @proved_conjs;
  my @new_proved = ();

  @cheatable_unpr{ @cheatable } = ();
  delete @cheatable_unpr{ @proved_conjs };

  # for each remaining cheatable, set its subref count in %cheatable_unpr
  foreach $conj (keys %cheatable_unpr)
  {

      my @subrefs = keys %{$gsubrefs{ $conj }};
      $cheatable_unpr{ $conj } = 1 + $#subrefs;
  }

  open(CHLOG, ">$cheat_log") or die "Cannot write $cheat_log";
  open(SPEC, ">$filestem.spec_$iter" . "_cheat") or die "Cannot write spec_$iter _cheat file";

  # then decrease the subrefs counts by running through proved conjs
  # set the spec info in %cheat_specs and in %gresults
  while ( $#old_proved >= 0)
  {

      print CHLOG "EXTERNAL: $#old_proved\n";
      my @tmp = keys %cheatable_unpr;
      print CHLOG "$#tmp\n";

      foreach $pr_conj (@old_proved)
      {

	  print CHLOG "LOOP: $pr_conj\n";

	  # only interested in cheatable unproved conjs
	  foreach $unpr_cheat (keys %cheatable_unpr)
	  {
	      print CHLOG "TESTING: $unpr_cheat\n";
#	      print keys %{$gsubrefs{$unpr_cheat}}, "\n";
	      if (($cheatable_unpr{ $unpr_cheat } > 0) &&
		  (exists ${$gsubrefs{$unpr_cheat}}{$pr_conj}))
	      {
		  print CHLOG "$unpr_cheat: $cheatable_unpr{ $unpr_cheat }\n";
		  print CHLOG keys %{$gsubrefs{$unpr_cheat}}, "\n";
		  $cheatable_unpr{ $unpr_cheat } =  $cheatable_unpr{ $unpr_cheat } - 1;
		  print CHLOG "$unpr_cheat: $cheatable_unpr{ $unpr_cheat }\n";
		  if ( 0 == $cheatable_unpr{ $unpr_cheat })
		  {
		      print CHLOG "SUCCESS\n";
		      push(@new_proved, $unpr_cheat);

		      # compute the refernces from %gsubrefs and %gsuperrefs,
		      # update %gresults an %cheat_specs, print SPEC, and the problem file

		      my %refs = ();
		      @refs{ keys %{$gsuperrefs{ $unpr_cheat }} } = ();
		      foreach $conj (keys %{$gsubrefs{ $unpr_cheat }})
		      {
			  # ## ASSERT: last entry for $conj in %gresults is the solved one
			  my @conj_entries = @{$gresults{$conj}};
			  @refs{ @{$conj_entries[$#conj_entries]->[res_NEEDED]} } = ();
		      }

		      # note that there can now be sublevel references in %refs,
		      # irrelevant for $unpr_cheat - we have to filter it with $gspec{$unpr_cheat}
		      # also put the $unpr_cheat to first position in @spec
		      foreach $ref1 (keys %refs)
		      {
			  delete $refs{$ref1} unless exists ${$gspec{$unpr_cheat}}{$ref1};
		      }
		      my @spec = ( $unpr_cheat );
		      push( @spec,  keys %refs);

		      $cheat_specs{$unpr_cheat} = [ @spec ];

		      my $new_spec = [szs_INIT, $#spec, -1, [@spec], [@spec] ];
		      push(@{$gresults{ $unpr_cheat}}, $new_spec);

		      my $new_refs = join(",", @spec);
		      print SPEC "spec($spec[0],[$new_refs]).\n";
		      PrintPruned($iter . "_cheat", $file_prefix, $file_postfix, \@spec);
		  }
	      }
	  }
      }

      @old_proved = @new_proved;
      @new_proved = ();
  }

  close(SPEC);
  close(CHLOG);
  return \%cheat_specs;
}








# structure of the results file:
# results(ConjectureName,OverallSZSStatus,FullSpec,AllowedLemmas,NeededAxioms,OverallTime,
#         [result(IterationNumber,SZSStatus,Spec,Time,[UsefulData]), result(....), ...]).
# where OverallSZSStatus is Unknown, Theorem, CounterSatisfiable (the last should not happen),
# FullSpec is the original list of axioms
# AllowedLemmas are newly invented lemmas logically following from FullSpec, which are therefore
#               eligible for addin to Spec
# NeededAxioms is nonempty only if the OverallSZSStatus is Theorem - then it is
#              a subset of FullSpec and AllowedLemmas
# OverallTime is the time devoted to all proof attempts on this problem
#
# for each result:
# IterationNumber is the iteration duiring whicha result was measured
# SZSStatus is again is the result status (it can be CounterSatisfiable for nonfull spec)
# Spec should be a subset of FullSpec plus AllowedLemmas; 
# Time is the time it took to compute this result
# UsefulData is now empty (may be e.g. other proof characteristics later
#
# memory representation:
# hash( 'conjecture' => ConjectureName,
#       



# When should lemmas generated in problem A be allowed to be used for problem B in bushy and chainy:
# it's simple: whenever they are generated from (a subset of) the axioms of B


# The initial .proved_by_0 table can be created from the .refnr
# file by running:
# sed -e 's/\(.*\)/proved_by(\1,[\1])./' <foo.refnr > foo.proved_by_0
#
# On the result training file .train_0, snow can be run this way (provided
# 1234 is the number of all references, i.e. `wc -l foo.refnr`)
# snow -train -I foo.train_0 -F foo.net_0  -B :0-1234
#
# Further iterations can be obtained e.g. from succesfull proofs, for SPASS e.g. this way:
# grep "Formulae used in the proof" */*.out| sed -e 's/.*__\(.*\).ren.dfg.*: *\(.*\) */proved_by(\1,[\2])./' |tr " " "," > 00zoo

# Translate ATP results into numerical training data.
# The results (i.e. inputs) have the following form:
# proved_by(t5_connsp_2,[t5_connsp_2,d1_connsp_2,t4_subset,t55_tops_1]).
# We fetch the symbols for t5_connsp_2 from %grefsyms, translate them
# to numbers by %gsymnr, and add the numbers of references obtained using %grefnr
# (t5_connsp_2 usually appears) there too, as it was the conjecture, and
# we don't remove it.
sub PrintTraining
{
    my ($iter) = @_;
#    LoadTables();
    open(PROVED_BY, "$filestem.proved_by_$iter") or die "Cannot read proved_by_$iter file";
    open(TRAIN, ">$filestem.train_$iter") or die "Cannot write train_$iter file";
    while (<PROVED_BY>) {
	my ($ref,$refs);

	m/^proved_by\( *([a-z0-9A-Z_]+) *, *\[(.*)\] *\)\./ 
	    or die "Bad proved_by info: $_";

	($ref, $refs) = ($1, $2);
	my @refs = split(/\,/, $refs);
	my @refs_nrs   = map { $grefnr{$_} if(exists($grefnr{$_})) } @refs;
	my @syms = @{$grefsyms{$ref}};
	my @syms_nrs   = map { $gsymnr{$_} if(exists($gsymnr{$_})) } @syms;
	my @all_nrs = (@refs_nrs, @syms_nrs);
	# just a sanity check
	foreach $ref (@refs)
	{
	    exists $grefsyms{$ref} or die "Unknown reference $ref in $_";
	    exists $grefnr{$ref} or die "Unknown reference $ref in $_";
	}
	my $training_exmpl = join(",", @all_nrs);
	print TRAIN "$training_exmpl:\n";
    }
    close PROVED_BY;
    close TRAIN;
}


# Create a .train_$iter file from the %proved_by hash, where keys are proved
# conjectures and values are arrays of references needed for the proof.
# All the $filestem.train_* files are afterwards cat-ed to $filestem.alltrain_$iter
# file, on which Learn() works.
sub PrintTrainingFromHash
{
    my ($iter,$proved_by) = @_;
    my $ref;
    open(TRAIN, ">$filestem.train_$iter") or die "Cannot write train_$iter file";
    foreach $ref (sort keys %$proved_by) {
	my @refs = @{$proved_by->{$ref}};
	my @refs_nrs   = map { $grefnr{$_} if(exists($grefnr{$_})) } @refs;
	my @syms = @{$grefsyms{$ref}};
	my @syms_nrs   = map { $gsymnr{$_} if(exists($gsymnr{$_})) } @syms;
	my @all_nrs = (@refs_nrs, @syms_nrs);
	# just a sanity check
	foreach $ref (@refs)
	{
	    exists $grefsyms{$ref} or die "Unknown reference $ref in $_";
	    exists $grefnr{$ref} or die "Unknown reference $ref in $_";
	}
	my $training_exmpl = join(",", @all_nrs);
	print TRAIN "$training_exmpl:\n";
    }
    close TRAIN;
}


# PrintTesting(0);
#PrintTraining(0);
die "finished";
