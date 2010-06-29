use strict;
use warnings;
use Test::More;
use lib './t';
use Mock::Basic;

Mock::Basic->dbh_resolver->conf(
    +{
        connect_info => +{
            MASTER => +{
                dsn => 'dbi:SQLite:./t/db/master.db',
            },
            MASTER1_1 => +{
                dsn => 'dbi:SQLite:./t/db/master1_1.db',
            },
            MASTER1_2 => +{
                dsn => 'dbi:SQLite:./t/db/master1_2.db',
            },
            MASTER2_1 => +{
                dsn => 'dbi:SQLite:./t/db/master2_1.db',
            },
            MASTER2_2 => +{
                dsn => 'dbi:SQLite:./t/db/master2_2.db',
            },
        },
        clusters => +{
            MASTER1 => [ qw/MASTER1_1 MASTER1_2/ ],
            MASTER2 => [ qw/MASTER2_1 MASTER2_2/ ],
        },
    }
);

is_deeply [Mock::Basic->dbh_resolver->cluster('MASTER1')], [qw/MASTER1_1 MASTER1_2/];

is_deeply +Mock::Basic->dbh_resolver->connect_info('MASTER'), {
    dsn => 'dbi:SQLite:./t/db/master.db',
};

is_deeply +Mock::Basic->dbh_resolver->connect_info('MASTER1', +{ strategy => 'Remainder', key => 1 }), {
    dsn => 'dbi:SQLite:./t/db/master1_2.db',
};

is_deeply +Mock::Basic->dbh_resolver->connect_info('MASTER1', +{ strategy => 'Remainder', key => 2 }), {
    dsn => 'dbi:SQLite:./t/db/master1_1.db',
};

# do connect
my $id = 1;
Mock::Basic->dbh_resolver->connect('MASTER1', +{ strategy => 'Remainder', key => $id });

Mock::Basic->setup_test_db;
Mock::Basic->insert('mock_basic',{id => $id, name => 'foo'});
ok +Mock::Basic->single('mock_basic', {id => $id});

$id = 2;

Mock::Basic->dbh_resolver->connect('MASTER1', +{ strategy => 'Remainder', key => $id });
Mock::Basic->setup_test_db;
ok not +Mock::Basic->single('mock_basic', {id => $id});

unlink('./t/db/master1_1.db', './t/db/master1_2.db');

done_testing;

