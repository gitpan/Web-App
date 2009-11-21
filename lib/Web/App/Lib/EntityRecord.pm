package Web::App::Lib::EntityRecord;

use Class::Easy;

sub info {
	my $class  = shift;
	my $app    = shift;
	my $params = shift;
	
	my $entity = $app->project->entity ($params->{entity_type});
	
	my $record;
	if ($params->{fuzzy}) {
		$record = $entity->fetch ($params);
	} else {
		my $record_id = $params->{entity_id};
		$record = $entity->fetch_by_id ($record_id);
	}

	return [$record || {}];
}

sub store {
	my $class = shift;
	my $app   = shift;
	my $params = shift;
	
	my $req = $app->request;
	
	my $record_id = $params->{entity_id};
	
	use Data::Dumper;
	debug Dumper $req->params;

	my $entity = $app->project->entity ($params->{entity_type});
	
	my $fields = $entity->fields;
	
	my @field_names = keys %$fields;
	
	my @required_params;
	my @allowed_params;
	
	foreach (@field_names) {
		next if defined $fields->{$_}->{X_IS_PK}; # look: special processing
		
		if ($fields->{$_}->{nullable} == 0 and ! defined $fields->{$_}->{default}) {
			push @required_params, $_;
			next;
		}
		
		push @allowed_params, $_;
	}
	
	my $record = {};
	$record->{$entity->_pk_} = $record_id
		if defined $record_id and $record_id =~ /^\d+$/;

	foreach my $param (@required_params) {
		my $param_value = $app->request->param ($param);
		# TODO: send an error mesage
		unless (defined $param_value) {
			$app->var->{msg} = "обязательный параметр $param не задан";
			return;
		}
		
		$record->{$param} = $param_value;
	}
	
	foreach my $param (@allowed_params) {
		my $param_value = $app->request->param ($param);
		$record->{$param} = $param_value
			if defined $param_value;
	}
	
	# TODO: check for booleans
	#my @checkboxes = qw(week is_active);
	#
	#foreach my $param (@checkboxes) {
	#	$news_item->{$param} = $app->request->param ($param) ? 1 : 0;
	#}
	
	my $item = $entity->new ($record);

	my $result;

	if ($record->{$entity->_pk_} and $record->{$entity->_pk_} =~ /^\d+$/) {
		$result = $item->update;
	} else {
		$result = $item->create;
	}
	
	if ($result) {
		$app->var->{success} = 'ok';
		$app->var->{entity_id} = $item->id;
	} else {
		debug Dumper $record;
		$app->var->{msg} = "невозможно сохранить — обратитесь к разработчику";
	}
	
	return;
}

1;
