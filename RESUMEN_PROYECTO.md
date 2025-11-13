RESUMEN

El presente proyecto de grado se desarrolló con el propósito de brindar a instituciones académicas un sistema multiplataforma (web y aplicación móvil) para la gestión, emisión y validación de certificados académicos mediante tecnología blockchain, lo cual facilita la realización de dichos procesos, con el fin de mejorar el manejo de información, garantizar la autenticidad y trazabilidad de los certificados emitidos, y prevenir la falsificación de documentos académicos en las instituciones educativas.

Además de enfocarse en el sistema web y aplicación móvil, este proyecto también adoptó una metodología de desarrollo ágil, la cual garantiza una gestión eficaz del proyecto mediante iteraciones incrementales y entregas continuas, permitiendo la adaptación constante a los requisitos del sistema.

El desarrollo del sistema multiplataforma se realizó utilizando el framework Flutter (Dart), empleando una arquitectura multi-tenant que permite a múltiples instituciones gestionar sus certificados de manera independiente. El frontend se implementó siguiendo el patrón de diseño de arquitectura en capas (Capa de Presentación, Capa de Lógica de Negocio y Capa de Persistencia), mientras que la comunicación con el backend se realiza mediante servicios en la nube de Firebase (Firestore, Authentication y Storage). Por su parte, la integración con blockchain se implementó a través de contratos inteligentes desarrollados en Solidity sobre la red Polygon, empleando el lenguaje de programación Dart mediante la librería web3dart para la comunicación con la blockchain. La base de datos NoSQL Cloud Firestore se utiliza para el almacenamiento de información de usuarios, instituciones y certificados, mientras que los hashes de los certificados se registran de forma inmutable en la blockchain para garantizar su autenticidad y trazabilidad.

Posterior al desarrollo exhaustivo del sistema, se llevaron a cabo una serie de pruebas de calidad, abarcando aspectos cruciales como la usabilidad, la compatibilidad con múltiples plataformas (Web, Android, iOS) y dispositivos, el rendimiento en diversas condiciones y escenarios, y la validación de la integridad y autenticidad de los certificados mediante blockchain, con el fin de garantizar que dichos aspectos reflejen un nivel óptimo de calidad.

El resultado final del presente proyecto es un sistema multiplataforma (web y aplicación móvil) diseñado para permitir la optimización y agilización de las labores diarias de emisión y validación de certificados académicos en instituciones educativas, garantizando mediante tecnología blockchain la autenticidad, seguridad e inmutabilidad de los documentos emitidos.

Palabras clave: Certificados académicos, Blockchain, Sistema multiplataforma, Flutter, Firebase, Polygon, Multi-tenant, Contratos inteligentes


