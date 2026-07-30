# Consulta Placas

App Flutter (Android) que consulta o valor de mercado de um veículo pela Tabela FIPE e mostra uma foto ilustrativa do modelo. Sem login, sem chave de API, sem custo — roda direto com `flutter run`.

## Como funciona

O usuário escolhe **tipo de veículo → marca → modelo → ano** (em telas de busca com filtro, não dropdowns nativos) e o app retorna:

- Valor da Tabela FIPE, código FIPE, combustível e mês de referência
- Uma foto ilustrativa do modelo (não é a foto do carro físico do usuário — nenhuma fonte gratuita ou paga oferece isso; é uma foto de referência do modelo/ano)

Não existe busca por placa. Essa possibilidade foi avaliada e descartada — ver [Decisões e caminhos descartados](#decisões-e-caminhos-descartados) para o motivo.

## Stack

- Flutter 3.x / Dart 3.12+, Material 3
- **MVVM manual**: `ChangeNotifier` + `ViewModelWidget<T>` (sem o pacote `provider`)
- **DI**: `get_it`
- **Rotas**: `go_router`
- **HTTP**: `Dio`
- **Cache local**: `shared_preferences` (só para as fotos já encontradas)
- **Testes**: `flutter_test` + `mocktail`

## Fontes de dados (100% gratuitas, sem chave)

### Valor FIPE — [parallelum.com.br/fipe](https://parallelum.com.br/fipe)
API pública e gratuita, sem limite de requisições. Fluxo em cascata por código:

```
GET /fipe/api/v1/{tipo}/marcas
GET /fipe/api/v1/{tipo}/marcas/{codigoMarca}/modelos
GET /fipe/api/v1/{tipo}/marcas/{codigoMarca}/modelos/{codigoModelo}/anos
GET /fipe/api/v1/{tipo}/marcas/{codigoMarca}/modelos/{codigoModelo}/anos/{codigoAno}
```
`{tipo}` é `carros`, `motos` ou `caminhoes`. Implementado em [`lib/data/repository/fipe_repository.dart`](lib/data/repository/fipe_repository.dart).

> A BrasilAPI também expõe uma Tabela FIPE (`/fipe/*`), mas na época em que este projeto foi feito seus endpoints estavam retornando erro 500 (a fonte de dados deles bloqueava as requisições). Por isso a parallelum foi escolhida como fonte oficial.

### Foto ilustrativa — Wikipedia / Wikimedia
Sem chave, sem limite. Implementado em [`lib/data/repository/photo_repository.dart`](lib/data/repository/photo_repository.dart):

1. Extrai o **nome-base do modelo** (só a primeira palavra, ex: de `"PULSE DRIVE 1.3 8V Flex Mec."` usa só `"PULSE"`) — a Tabela FIPE inclui motorização/câmbio no nome do modelo, e isso quebra a busca na Wikipedia se usado por inteiro.
2. Busca `{marca} {nome-base}` na Wikipedia em **português**; se o tipo do veículo for moto ou caminhão, adiciona uma dica no idioma certo (`motocicleta`/`caminhão`) para evitar que a busca caia numa página errada (ex: sem a dica, "Honda Pop" batia no artigo do carro esportivo "Honda NSX").
3. Se não achar foto em português, tenta de novo em **inglês** (`motorcycle`/`truck`) — cobre modelos muito novos ou nichados que ainda não têm página em PT.
4. Resultado é cacheado em `shared_preferences` por `marca+nome-base+tipo`, então a mesma combinação nunca busca de novo no mesmo aparelho.
5. Se nada for encontrado, a tela mostra um ícone de carro genérico no lugar da foto.

Essa é uma heurística, não uma correspondência garantida — cobre bem a maioria dos modelos comuns, mas pode falhar ou trazer uma foto de uma versão diferente do mesmo nome-base (ex: buscar "Corolla Cross" pode achar a página do Corolla sedã comum).

## Arquitetura

```
lib/
  core/
    di/service_locator.dart        # get_it: registra Dio, repositórios e ViewModels
    router/app_router.dart         # go_router: '/' e '/resultado'
    mvvm/
      base_view_model.dart         # ChangeNotifier com isLoading/errorMessage
      view_model_widget.dart       # StatefulWidget genérico que escuta um ChangeNotifier
    theme/app_theme.dart           # Material 3 + Google Fonts (Poppins)
    util/
      text_normalizer.dart         # remove acentos/caixa para comparações e chaves de cache
      network_error_message.dart   # traduz DioException em mensagem amigável
    widget/
      searchable_picker_page.dart  # tela cheia de busca+lista reutilizada por marca/modelo/ano
  data/
    model/
      fipe_option.dart             # {code, name} — item de marca/modelo/ano
      fipe_value.dart              # resultado final da consulta FIPE
      vehicle_type.dart            # enum carros/motos/caminhoes
      vehicle_result_data.dart     # FipeValue + url da foto, passado pra tela de resultado
    repository/
      fipe_repository.dart
      photo_repository.dart
  module/
    vehicle_search/
      view/vehicle_search_page.dart
      viewmodel/vehicle_search_view_model.dart
    vehicle_result/
      view/vehicle_result_page.dart   # StatelessWidget simples (não precisa de ViewModel próprio)
  main.dart
test/
  data/repository/
    fipe_repository_test.dart
    photo_repository_test.dart
```

**Padrão MVVM**: `ViewModelWidget<T extends ChangeNotifier>` é um `StatefulWidget` genérico que faz `addListener`/`removeListener` no `ChangeNotifier` recebido e chama `setState` a cada mudança — sem depender do pacote `provider`. `BaseViewModel` centraliza `isLoading` e `errorMessage`. A `VehicleResultPage` **não** usa esse padrão: como ela só exibe dados já prontos (sem estado próprio, sem loading), é um `StatelessWidget` comum recebendo `VehicleResultData` direto — evita um ViewModel que não faria nada além de guardar um valor.

**Fluxo de erro/retry**: cada etapa da busca (carregar marcas, modelos, anos, ou a consulta final) guarda qual etapa falhou. `DioException` é traduzido em mensagem específica (sem conexão / servidor indisponível / erro genérico) via `network_error_message.dart`, e a tela mostra um botão "Tentar novamente" que reexecuta só a etapa que quebrou — não precisa refazer a seleção inteira.

## Rodando o projeto

Não precisa de nenhuma chave, conta ou arquivo de configuração.

```bash
flutter pub get
flutter run
```

## Testes

```bash
flutter test
```

Cobrem `FipeRepository` e `PhotoRepository` com `Dio` mockado (`mocktail`), incluindo os cenários reais de bug encontrados durante o desenvolvimento: nome-base do modelo, fallback PT→EN e a dica de tipo de veículo.

## Decisões e caminhos descartados

Documentado aqui para não repetir a mesma investigação no futuro:

- **Consulta por placa via ApiBrasil**: existe API veicular deles, mas é paga por requisição (~R$0,10) e a variante testada exige Conta PJ (CNPJ). Sem cota grátis confirmada.
- **Scraping do Carros na Web**: catálogo do site está com links quebrados (404) — não é uma fonte confiável.
- **Scraping do PlacaFipe.com**: o site está atrás de Cloudflare com desafio JavaScript; um cliente HTTP simples (como o `Dio` usado neste app) nunca passa por esse desafio. Contornar isso seria bypass de detecção de bot.
- **Google Custom Search API (foto)**: o Google descontinuou a opção "pesquisar em toda a Web" pra mecanismos novos (março de 2026) e agora exige conta de faturamento (cartão) vinculada ao projeto do Google Cloud mesmo pra uso dentro da cota grátis. Abandonado em favor da Wikipedia.
- **BrasilAPI (Tabela FIPE)**: endpoints de FIPE retornavam 500 (erro 403 da fonte de dados original deles) no momento em que o projeto foi feito. A parallelum, que usa a mesma fonte de dados, funcionava normalmente.

Se algum desses cenários mudar (ex: BrasilAPI FIPE voltar a funcionar, ou você decidir pagar pela ApiBrasil pra ter busca por placa), os repositórios em `lib/data/repository/` são o único lugar que precisa mudar — a UI e o ViewModel não dependem da fonte específica.
