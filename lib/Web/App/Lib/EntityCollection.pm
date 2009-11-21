package Web::App::Lib::EntityCollection;

use Class::Easy;

sub list {
	my $class  = shift;
	my $app    = shift;
	my $params = shift;
	
	my $entity_type = delete $params->{entity_type};
	
	$app->project->entity ($entity_type);
	my $collection = $app->project->collection ($entity_type)->new;
	
	# TODO: remove hack
	my $query = $app->request->params;
	
	my $query_params = {map {$_ => $query->{$_}->[0]} grep {! /CGI\:\:Minimal/} keys %$query};
	
	my $list = $collection->list ({%$params, %$query_params});
	
	return $list;
}


1;
