use sane;
use Test::More;
use Test::mysqld;
use DBI;
use t::CRUD;
use SQL::Maker;
local $ENV{PATH} = $ENV{PATH} . ':/usr/sbin'; # for debian + Test::mysqld use Test::mysqld;

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '',
        'character_set_server' => 'utf8',
    }
) or plan skip_all => $Test::mysqld::errstr;

t::CRUD->run(sub {
    my $dbh = DBI->connect(
        $mysqld->dsn, '', '',
        { RootClass => 'DBIx::Extended' }
    );
    return (sub {$dbh}, 'mysql', 'SQL::Abstract');
}->());

t::CRUD->run(sub {
    my $dbh = DBI->connect(
        $mysqld->dsn, '', '', {
            RootClass => 'DBIx::Extended',
            private_extended_builder => SQL::Maker->new(driver => 'mysql')
        }
    );
    return (sub {$dbh}, 'mysql', 'SQL::Maker');
}->());

done_testing;
