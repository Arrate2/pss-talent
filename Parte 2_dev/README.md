> Pra´ctica Terraform y AWS Claudia Arrate Esteve
>
> Pra´ctica final de Terraform y AWS
>
> Claudia Arrate Esteve
>
> 13 de noviembre de 2025
>
> Resumen
>
> En el siguiente documento se muestra paso por paso como se han
> realizado los dos ejer-cicios correspondientes a la Pra´ctica final de
> Terraform y AWS del II Talent Campus en Automatizacio´n + IA de la
> empresa PSS impartido por Joel Rosental. Dicha pr´actica se divide en
> un Parte II y una Parte III.
>
> 1 Parte II
>
> El siguiente apartado presenta los pasos de ejecucio´n implementados
> para el despliegue de un sitio web esta´tico sobre la infraestructura
> de Amazon Web Services (AWS) S3. El objetivo principal fue establecer
> una solucio´n de hosting robusta y completamente automatizada. Para
> ello se usara´n cinco pilares fundamentales: la creacio´n del bucket,
> la gestio´n de permisos pu´blicos, la aplicacio´n de pol´ıticas de
> acceso, la configuracio´n del hosting esta´tico y la carga de los
> objetos.
>
> 1.1 Aprovisionamiento de Infraestructura con Terraform
>
> Antes de empezar a crear el bucket se crearan manualmente los archivos
> index.html y error.html que se piden en los pasos 2 y 3. Estos
> archivos contienen un pequen˜o texto para indicarlo. El primero avisa
> de que esta´s en Terraform y el segundo muestra que la pa´gina no ha
> sido encontrada. Como u´ltimo prerrequisito an˜adiremos el documento
> provider.tf.
>
> 1.1.1 Creacio´n y Configuraci´on del Bucket S3
>
> Como primer paso (pasos 1 y 4 de la hoja de enunciado) se crea el
> recurso principal, el bucket S3, el cual debe poseer un nombre u´nico
> a nivel global. Adicionalmente, y de manera cr´ıtica para la
> exposicio´n pu´blica del sitio, se activan expl´ıcitamente todas las
> reglas dentro del Public Access Block de AWS, conforme a la normativa
> de acceso. El co´digo que se muestra a continuacio´n ira´ en el
> archivo main.tf.
>
> Listing 1: Creacio´n del Bucket y Desactivacio´n del Bloqueo Pu´blico
>
> 1 \# 1. Creacion del Bucket S3
>
> 2 resource "aws_s3_bucket" "mi_bucket_ejemplo" {
>
> 3 bucket = "claudia-ae-pss" \#los nombres de buckets no aceptan
> mayusculas
>
> 4
>
> 5 tags = { 6 Name
>
> 7 Environment 8 }
>
> 9 }

10

= "MiBucketDesdeTerraform" = "Dev"

11 \# 2. Activacion del Public Access Block (Punto 4)

12 resource "aws_s3_bucket_public_access_block" "public_access_block" {
13 bucket = aws_s3_bucket.website_bucket.id

> 1
>
> Pra´ctica Terraform y AWS Claudia Arrate Esteve

14 block_public_acls = true 15 block_public_policy = true 16
ignore_public_acls = true 17 restrict_public_buckets = true 18 }

19

20 \# Habilita el control de versiones (para poder recuperar objetos
eliminados/modificados)

21 resource "aws_s3_bucket_versioning" "versioning_config" { 22 bucket =
aws_s3_bucket.mi_bucket_ejemplo.id

23 versioning_configuration { 24 status = "Enabled"

25 } 26 }

> 1.1.2 Gestio´n de Pol´ıticas de Acceso (Punto 5)
>
> Para garantizar la accesibilidad al contenido web por parte de
> cualquier usuario a trav´es de Inter-net, se implementa una aws s3
> bucket policy. Esta pol´ıtica otorga el permiso s3:GetObject (lectura)
> a todos los objetos dentro del bucket. El siguiente co´digo se
> an˜adira´ al archivo main.tf
>
> Listing 2: Pol´ıtica de Bucket para Acceso Pu´blico de Lectura
>
> 1 data "aws_iam_policy_document" "website_policy" { 2 statement {
>
> 3 principals {
>
> 4 type = "AWS" 5 identifiers = \["\*"\] 6 }
>
> 7 actions = \["s3:GetObject"\] 8 resources = \[
>
> 9 aws_s3_bucket.website_bucket.arn,

10 "\${aws_s3_bucket.website_bucket.arn}/\*", 11 \]

12 } 13 }

14 \#Aplicar la politica al bucket

15 resource "aws_s3_bucket_policy" "website_policy" { 16 bucket =
aws_s3_bucket.website_bucket.id

17 depends_on =
\[aws_s3_bucket_public_access_block.public_access_block\] 18 policy =
data.aws_iam_policy_document.website_policy.json

19 }

> Adema´s para que esto funcione es necesario realizar los siguientes
> cambios el el co´digo que se ten´ıa anteriormente.
>
> Listing 3: Modificaci´on de c´odigo
>
> 1 \# 2. Activacion del Public Access Block
>
> 2 resource "aws_s3_bucket_public_access_block" "public_access_block" {
> 3 bucket = aws_s3_bucket.mi_bucket_ejemplo.id
>
> 4 block_public_acls = true
>
> 5 block_public_policy = false \#\<--6 ignore_public_acls = true
>
> 7 restrict_public_buckets = false \#\<--8 }
>
> 2
>
> Pra´ctica Terraform y AWS Claudia Arrate Esteve
>
> 1.1.3 Configuraci´on del Hosting Est´atico (Punto 6)
>
> Se habilita la funcionalidad de sitio web esta´tico de S3. Para ello
> se hace uso del recurso aws s3 bucket website configuration,
> definiendo index.html y error.html como documen-tos de´ındice y error,
> respectivamente.
>
> Listing 4: Configuracio´n del Hosting de Sitio Web Esta´tico
>
> 1 resource "aws_s3_bucket_website_configuration" "website_config" { 2
> bucket = aws_s3_bucket.mi_bucket_ejemplo.id
>
> 3 index_document {
>
> 4 suffix = "index.html" 5 }
>
> 6 error_document {
>
> 7 key = "error.html" 8 }
>
> 9 }
>
> Adem´as hay que crear el archivo outputs.tf con el siguiente contenido
> (punto 7).
>
> 1 \#Parte 7
>
> 2 output "website_endpoint" {
>
> 3 description = "El endpoint p blico del sitio web est tico S3." 4
> value = aws_s3_bucket_website_configuration.website_config.
>
> website_endpoint 5 }
>
> 6
>
> 7 output "website_url" {
>
> 8 description = "La URL completa del sitio web est tico S3 (usando la
> regi n )."

9 value = aws_s3_bucket.mi_bucket_ejemplo.website_endpoint 10 }

> 1.2 Gestio´n del Contenido y Pruebas
>
> 1.2.1 Carga de Archivos Mediante Terraform (Punto 8)
>
> Inicialmente, se realizo´ una carga manual de los archivos index.html
> y error.html para la veri-ficacio´n funcional. Ahoras se procede a la
> eliminacio´n de los archivos manuales y a la utilizacio´n del recurso
> aws s3 object para la carga programa´tica.
>
> Listing 5: Carga de Objetos de Contenido al Bucket
>
> 1 \# Carga de index.html
>
> 2 resource "aws_s3_object" "index" {
>
> 3 bucket = aws_s3_bucket.mi_bucket_ejemplo.id 4 key = "index.html"
>
> 5 source = "index.html" (Archivo local) 6 content_type = "text/html"
>
> 7 etag = filemd5("index.html") \#para mantener 8 }
>
> 9

10 \# Carga de error.html

11 resource "aws_s3_object" "error" {

12 bucket = aws_s3_bucket.mi_bucket_ejemplo.id 13 key = "error.html"

14 source = "error.html" 15 content_type = "text/html"

16 etag = filemd5("error.html") \#para mantener 17 }

cambios

cambios

locales

locales

> 3
>
> Pra´ctica Terraform y AWS Claudia Arrate Esteve
>
> 1.2.2 Depurado de co´digo (parte 9)
>
> Para que el co´digo sea ma´s legible se an˜aden tags a los recursos
> para identificar de forma sencilla que se esta´ haciendo en cada
> parte. Por ejemplo en la parte 8 an˜adimos a los recursos
> respectivamente:
>
> 1 tags = { 2 Project
>
> 3 ManagedBy
>
> 4 ContentRole 5 }
>
> 6
>
> 7 tags = { 8 Project
>
> 9 ManagedBy

10 ContentRole 11 }

= "StaticWebsite" = "Terraform"

= "FilePage"

= "StaticWebsite" = "Terraform"

= "ErrorPage"

> 1.3 Eliminacio´n de recursos (Punto 10)
>
> Finalmente, para cumplir con el requisito de gestio´n de costos, se
> recomienda la ejecucio´n de la funcio´n terraform destroy al concluir
> las pruebas, garantizando la eliminacio´n de todos los recursos
> aprovisionados.
>
> 4
