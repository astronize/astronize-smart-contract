// Sources flattened with hardhat v2.3.0 https://hardhat.org
pragma solidity 0.8.10;

interface IAdminProject {
    function rootAdmin() external view returns (address);

    function isSuperAdmin(address _addr, string calldata _project) external view returns (bool);

    function isAdmin(address _addr, string calldata _project) external view returns (bool);
}

contract AdminProjectRouter {
    modifier onlyRootAdmin() {
        require(adminProject.rootAdmin() == msg.sender, "Restricted only root admin");
        _;
    }

    IAdminProject public adminProject;

    constructor(address _adminProject) public {
        adminProject = IAdminProject(_adminProject);
    }

    function isSuperAdmin(address _addr, string calldata _project) external view returns (bool) {
        return adminProject.isSuperAdmin(_addr, _project);
    }

    function isAdmin(address _addr, string calldata _project) external view returns (bool) {
        return adminProject.isAdmin(_addr, _project);
    }

    function setAdminProject(address _adminProject) external onlyRootAdmin returns (bool) {
        adminProject = IAdminProject(_adminProject);
        return true;
    }
}