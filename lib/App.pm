package App;
use Dancer2;
use Redis;
use Data::Dumper;

our $VERSION = '0.1';
our $redis;

if(defined($ENV{REDIS_PASSWORD})) {
    $redis = Redis->new(server => "$ENV{REDIS_SERVER}:$ENV{REDIS_PORT}", password => "$ENV{REDIS_PASSWORD}", reconnect => 60, every => 2_000_000);
} else {
    $redis = Redis->new(server => "$ENV{REDIS_SERVER}:$ENV{REDIS_PORT}", reconnect => 60, every => 2_000_000);
}

unless ($redis->get('page')) {
    $redis->set('page' => q[<div id="getting-started">
      <h1>Volumes Persistentes</h1>
      <h2>Aqui está o que foi feito:</h2>
      <ol>
        <li>
          <h2>Um <b>PersistentVolume</b> foi criado</h2>
          <p>
          O <tt>PersistentVolume</tt> deve ser um <b>NFS</b>, a não ser
          que tenha trapaceado de alguma forma. Lembre-se que os <tt>PVs</tt>
          são criados pelos administradores. É possível provisionar dinâmicamente,
          mas não é o escopo do curso.
          </p>
        </li>
        <li>
          <h2>Depois um <b>Redis</b> foi provisionado</h2>
          <p>
          A aplicação <b>Redis</b>, através do <tt>Template</tt> no catálogo,
          criou por conta própria um <tt>PersistentVolumeClaim</tt>, conhecido
          também como <tt>PVC</tt>.
          </p>
        </li>
        <li>
            <h2>E então esta aplicação em <b>Perl</b> foi criada!</h2>
            <p>
            Esta aplicação se conecta ao <b>Redis</b> que está no endereço
            <tt><% REDIS_SERVER %></tt> e puxa toda esta página em HTML! Além disso
            do lado direito podemos ver alguns valores extraídos do <b>Redis</b>.
            </p>
        </li>
        <li>
            <h2>O que é <b>Dancer</b>?</h2>
            <p>
            <b>Dancer</b> é um microframework escrito em <b>Perl</b>, muito simples
            e bastante rápido para escrever pequenos serviços com <tt>API REST</tt>.
            </p>
        </li>
      </ol>
    </div>]);
}

get '/' => sub {
    my $page = $redis->get('page');
    my $info = $redis->info();
    my %redis_values;
    while(my ($key, $value) = each(%{$info})) {
        if (index($key, 'memory') != -1) {
           $redis_values{$key} = $value;
        }
    }
    #return Dumper(\%redis_values);
    template 'index', {'page' => $page, 'redis' => \%redis_values, 'REDIS_SERVER' => "$ENV{REDIS_SERVER}:$ENV{REDIS_PORT}"};
};

post '/update' => sub {
    my $json = from_json(request->body);
    my $html = %{$json}{html};
    $redis->set('page' => $html);
    status 201;
    response_header 'Content-Type' => 'application/json';
    encode_json({message => 'Página atualizada com sucesso!'});
};

true;
