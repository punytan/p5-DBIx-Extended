use sane;
use DBI;
use Benchmark 'cmpthese';
use SQL::Abstract;

my $abstract = SQL::Abstract->new;
my $sql = "CREATE TABLE sake (id INTEGER PRIMARY KEY, name TEXT)";
my @kubota = qw/生原酒 萬寿 翠寿 碧寿 紅寿 千寿 百寿/;

my $sec = 5;
say "Running 2 bench x $sec sec.";

my $dbh = DBI->connect('dbi:SQLite:memory:', '', '', {
    RaiseError => 1,
    PrintError => 1,
    ShowErrorStatement  => 1,
    AutoInactiveDestroy => 1,
    sqlite_unicode      => 1,
});

my $extended = DBI->connect(
    'dbi:SQLite:memory:', '', '',
    {RootClass => 'DBIx::Extended'}
);

cmpthese("-$sec", {
    extended => sub { extended($extended) },
    bare => sub { bare($dbh) },
});

sub bare {
    my $dbh = shift;
    $dbh->do("DROP TABLE sake");
    $dbh->do($sql);

    for (1 .. 20) {
        for my $name (@kubota) {
            my ($stmt, @bind) = $abstract->insert(sake => {
                name => $name
            });
            $dbh->prepare($stmt)->execute(@bind);
        }

        {
            my ($stmt, @bind) = $abstract->select('sake', ['*'], { id => 1 });
            my $result = $dbh->selectrow_hashref($stmt, {}, @bind);
        }

        {
            my ($stmt, @bind) = $abstract->select('sake', ['*']);
            my $resutl = $dbh->selectall_arrayref($stmt, {Slice => {}}, @bind);
        }

    }
}

sub extended {
    my $dbh = shift;
    $dbh->do("DROP TABLE sake");
    $dbh->do($sql);

    for (1 .. 20) {
        for my $name (@kubota) {
            $dbh->insert(sake => { name => $name });
        }

        { my $result = $dbh->select('sake', ['*'], { id => 1 }) }

        { my $result = $dbh->selectall('sake', ['*']) }
    }
}

__END__

