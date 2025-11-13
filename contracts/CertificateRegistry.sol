// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title CertificateRegistry
 * @dev Contrato inteligente para registrar certificados en la blockchain
 * @notice Este contrato permite emitir y verificar certificados de forma inmutable
 * Costo aproximado por certificado: ~0.001-0.01 MATIC (menos de $0.01 USD)
 */
contract CertificateRegistry {
    // Estructura de un certificado
    struct Certificate {
        string certificateId;      // ID único del certificado
        string studentId;           // ID del estudiante
        string institutionId;       // ID de la institución
        string certificateHash;     // Hash único del certificado
        uint256 issuedAt;           // Timestamp de emisión
        address issuedBy;           // Dirección del emisor
        bool revoked;              // Estado de revocación
    }
    
    // Mapeo de hash del certificado a los datos del certificado
    mapping(string => Certificate) public certificates;
    
    // Mapeo para verificar si un certificado existe
    mapping(string => bool) public certificateExists;
    
    // Lista de todos los hashes de certificados
    string[] public allCertificates;
    
    // Eventos
    event CertificateIssued(
        string indexed certificateId,
        string indexed certificateHash,
        string studentId,
        string institutionId,
        address indexed issuedBy,
        uint256 issuedAt
    );
    
    event CertificateRevoked(
        string indexed certificateId,
        string indexed certificateHash,
        address indexed revokedBy,
        uint256 revokedAt
    );
    
    // Dirección del administrador (quien puede revocar)
    address public admin;
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    constructor() {
        admin = msg.sender;
    }
    
    /**
     * @dev Emitir un nuevo certificado en la blockchain
     * @param _certificateId ID único del certificado
     * @param _studentId ID del estudiante
     * @param _institutionId ID de la institución
     * @param _certificateHash Hash único del certificado (generado off-chain)
     */
    function issueCertificate(
        string memory _certificateId,
        string memory _studentId,
        string memory _institutionId,
        string memory _certificateHash
    ) public {
        require(bytes(_certificateHash).length > 0, "Certificate hash cannot be empty");
        require(!certificateExists[_certificateHash], "Certificate already exists");
        
        Certificate memory newCertificate = Certificate({
            certificateId: _certificateId,
            studentId: _studentId,
            institutionId: _institutionId,
            certificateHash: _certificateHash,
            issuedAt: block.timestamp,
            issuedBy: msg.sender,
            revoked: false
        });
        
        certificates[_certificateHash] = newCertificate;
        certificateExists[_certificateHash] = true;
        allCertificates.push(_certificateHash);
        
        emit CertificateIssued(
            _certificateId,
            _certificateHash,
            _studentId,
            _institutionId,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @dev Emitir múltiples certificados en una sola transacción (más económico)
     * @param _certificateIds Array de IDs de certificados
     * @param _studentIds Array de IDs de estudiantes
     * @param _institutionIds Array de IDs de instituciones
     * @param _certificateHashes Array de hashes de certificados
     */
    function issueCertificatesBatch(
        string[] memory _certificateIds,
        string[] memory _studentIds,
        string[] memory _institutionIds,
        string[] memory _certificateHashes
    ) public {
        require(
            _certificateIds.length == _studentIds.length &&
            _studentIds.length == _institutionIds.length &&
            _institutionIds.length == _certificateHashes.length,
            "Arrays must have the same length"
        );
        
        for (uint i = 0; i < _certificateHashes.length; i++) {
            require(bytes(_certificateHashes[i]).length > 0, "Certificate hash cannot be empty");
            require(!certificateExists[_certificateHashes[i]], "Certificate already exists");
            
            Certificate memory newCertificate = Certificate({
                certificateId: _certificateIds[i],
                studentId: _studentIds[i],
                institutionId: _institutionIds[i],
                certificateHash: _certificateHashes[i],
                issuedAt: block.timestamp,
                issuedBy: msg.sender,
                revoked: false
            });
            
            certificates[_certificateHashes[i]] = newCertificate;
            certificateExists[_certificateHashes[i]] = true;
            allCertificates.push(_certificateHashes[i]);
            
            emit CertificateIssued(
                _certificateIds[i],
                _certificateHashes[i],
                _studentIds[i],
                _institutionIds[i],
                msg.sender,
                block.timestamp
            );
        }
    }
    
    /**
     * @dev Revocar un certificado (solo admin)
     * @param _certificateHash Hash del certificado a revocar
     */
    function revokeCertificate(string memory _certificateHash) public onlyAdmin {
        require(certificateExists[_certificateHash], "Certificate does not exist");
        require(!certificates[_certificateHash].revoked, "Certificate already revoked");
        
        certificates[_certificateHash].revoked = true;
        
        emit CertificateRevoked(
            certificates[_certificateHash].certificateId,
            _certificateHash,
            msg.sender,
            block.timestamp
        );
    }
    
    /**
     * @dev Verificar si un certificado existe y es válido
     * @param _certificateHash Hash del certificado a verificar
     * @return exists Si el certificado existe
     * @return revoked Si el certificado está revocado
     * @return certificateId ID del certificado
     * @return issuedAt Timestamp de emisión
     */
    function verifyCertificate(string memory _certificateHash) 
        public 
        view 
        returns (
            bool exists,
            bool revoked,
            string memory certificateId,
            uint256 issuedAt
        ) 
    {
        exists = certificateExists[_certificateHash];
        if (exists) {
            Certificate memory cert = certificates[_certificateHash];
            revoked = cert.revoked;
            certificateId = cert.certificateId;
            issuedAt = cert.issuedAt;
        }
    }
    
    /**
     * @dev Obtener información completa de un certificado
     * @param _certificateHash Hash del certificado
     * @return Certificate Estructura completa del certificado
     */
    function getCertificate(string memory _certificateHash) 
        public 
        view 
        returns (Certificate memory) 
    {
        require(certificateExists[_certificateHash], "Certificate does not exist");
        return certificates[_certificateHash];
    }
    
    /**
     * @dev Obtener el total de certificados emitidos
     * @return uint256 Número total de certificados
     */
    function getTotalCertificates() public view returns (uint256) {
        return allCertificates.length;
    }
}

