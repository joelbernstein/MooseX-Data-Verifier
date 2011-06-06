package Data::Verifier::Reflector::DBIC;
use Moose;
use true;
use 5.12.0;
use Scalar::Util qw(blessed);
use MooseX::Types::DBIx::Class qw(ResultSource);
use Moose::Util::TypeConstraints;
use MooseX::Types::Moose qw(Str ClassName CodeRef );
use MooseX::Types::DateTime qw(DateTime Duration);

use MooseX::Data::Verifier::Role;
use Data::Verifier::Reflector::TraitFor::Moose::Meta::Class;

has result_source => (
    isa => ResultSource, is => 'ro', required => 1,
);

sub _classname {
    my $self = shift;
    my $schema_name = blessed($self->result_source->schema);
    return join("::", __PACKAGE__, "ReflectedFor", $schema_name, "Result", $self->result_source->source_name);
}

sub _make_metaclass_with_roles {
    my $self = shift;
    my $metaclass =
      Moose::Util::with_traits( "Moose::Meta::Class", "Data::Verifier::Reflector::TraitFor::Moose::Meta::Class" )
        ->create( $self->_classname => roles => ['MooseX::Data::Verifier::Role'] );
    $self->_add_attributes($metaclass);
    $metaclass;
}

sub make_class {
    my $self = shift;
    my $classname = $self->_classname;
    my $metaclass =
        Class::MOP::is_class_loaded($classname)
      ? Class::MOP::class_of($classname)
      : $self->_make_metaclass_with_roles;

    # FIXME - hack! this should be done on the metaclass not per object???
    my $object = $metaclass->new_object(@_);
    $object;
}

sub _add_attributes {
    my ($self, $meta) = @_;
    my %columns_info = %{ $self->result_source->columns_info };
    my @primary_columns = $self->result_source->primary_columns;

    my $profile = {};
    COLUMN:
    while ( my ( $col_name, $col_info ) = each %columns_info ) {
        # hack? should this be a check for is_autoincrement => 1 instead? FIXME
        next COLUMN if $col_name ~~ @primary_columns;

        my $type;
        my $coerce = 0;
        given ( $col_info->{data_type} ) {
            when ( qr/(?:(?:(?:big|small)int)| (?:big?)serial| integer/x) {
                $type = "Int";
            }
            when {qr/(?:numeric|decimal|real| double(?:\s precision)?)/x) {
                $type = 'Num';
            }
            when (qr/(?:text|(?:var)?char)/) {
                $type = "Str";
            }
            when ("interval") {
                $type = "Duration";
                $coerce = 1;
            }
            when (qr/(?:date|time)/) {
                $type = "DateTime";
                $coerce = 1;
            }
            default {
                $type => 'Value',
            }
        }

        my $attr_options = {
            isa      => $type,
            is       => 'rw',
            coerce   => $coerce,
            required => $col_info->{is_nullable} // 0 ? 0 : 1,
        };
        
        $profile->{$col_name} = $attr_options;
        #$meta->add_attribute($col_name => (%$attr_options) );
    }
    $meta->dv_profile($profile);
};
