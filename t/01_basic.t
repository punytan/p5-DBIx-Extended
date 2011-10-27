use sane;
use Test::More;
use DBI;
use t::CRUD;

t::CRUD->run(sub {
    my $dbh = DBI->connect(
        'dbi:SQLite:dbname=:memory:', '', '', {
            RootClass => 'DBIx::Extended'
        }
    );

    return (sub {$dbh}, 'SQLite', 'SQL::Abstract');
}->());

done_testing;
