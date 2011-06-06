package MooseX::Data::Verifier::Role;
use Moose::Role;
use 5.010;

has _verify_result => (
    isa => 'Data::Verifier::Results', is => 'rw',
    lazy_build => 1, clearer => 'reset_verification',
    handles => {
        verification_success          => 'success',
        verification_fields_missing   => 'missings',
        verification_fields_invalid   => 'invalids',
        verification_field_is_wrong   => 'is_wrong',
        verification_field_is_valid   => 'is_valid',
        verification_field_is_invalid => 'is_invalid',
        verification_field_is_missing => 'is_missing',
        verified_fields               => 'valid_values',
    },
);

sub _build__verify_result { shift->verify; }

sub verify {
    my ($self, $data) = @_;
    #$data //= { $self->get_columns };
use DDS; warn "verify data:\n", Dump($data);
    my $result = $self->meta->verify( $data // $self->_dv_data_to_verify);
    $self->_verify_result($result);
    $result;
}

sub _dv_data_to_verify {
    my $self = shift;
use DDS; warn Dump($self->meta->dv_profile);
    my @keys = $self->meta->dv_attribute_names;
    my $data = { map { $_ => $self->meta->find_attribute_by_name($_)->get_value($self) } @keys };
    $data;
}

1;
