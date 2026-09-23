# Measurement Lab → bridgee-ios-sdk

Base inspecionada: `2f2b74bb5c95a6dabe4bf4a988f46aa92fdd65a7` (main em 22/09/2026).

[Mapa completo, origem e dependências](https://github.com/bridgee-ai/bridgee-measurement-lab/blob/codex/lab-migration-plan/docs/MIGRACAO_BRIDGEE_AI.md).

## Delta desta rodada

A entrega analytics para de emitir `first_open` e `<tenant>_first_open`; Firebase é
dono desses eventos. O método público firstOpen, completion de dois argumentos,
retorno vazio no 404, campaign_details, propriedades e dryRun são preservados.
A entrega foi isolada internamente para teste sem rede; o teste obsoleto que chamava
uma assinatura async inexistente foi corrigido. Nenhuma release SPM/Pod foi criada.

## Reaproveitar

`MatchBundle.setCustom` já transporta campos novos. Conservar URLSession,
AnalyticsProvider, APIRequest/APIResponse e a superfície Swift/Obj-C. Não adicionar
Firebase como dependência do SDK nem copiar a implementação Android.

## Dependências e próximos deltas

- Depois de API-01/02, decodificar metadados opcionais mantendo UTMs e clientes antigos.
- Links universais recebidos pelo app entram pelo MatchBundle; isso não implementa
  sozinho deferred deep linking após instalação. Formalizar o mecanismo suportado.
- Mesma política de native Google, conflito, orgânico e consentimento do Android;
  bridgee_install_id somente a partir do servidor e com consentimento.
- Persistir estado de entrega por tenant/app/instalação; definir reinstalação e
  reatribuição. AnalyticsProvider não confirma sozinho uma entrega exactly-once.
- Não emitir purchase ou interceptar chamadas Firebase. BigQuery é o caminho
  padrão para qualidade; checkpoint depende de receptor persistente.
- Revogação, retenção, reason codes e PrivacyInfo.xcprivacy acompanham mudanças
  efetivas de dados, sem declarar coleta que não existe.

## Release/aceite

Documentar retirada de `<tenant>_first_open` para consumidores. Atualizar podspec/tag,
RN e exemplo depois da release aprovada. Testar Swift e Obj-C, callback, dryRun,
404, offline/retry, consentimento, native Google e DebugView. Testes de entrega não
homologam Universal Links, aquisição via App Store ou Firebase em dispositivo.
