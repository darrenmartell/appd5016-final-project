import { Link, useLocation } from 'react-router-dom';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

const SidebarItem = ({ href, label, isCollapsed, icon }) => {
  const location = useLocation();
  const isActive = location.pathname === href;

  return (
    <li className="group">
      <Link
        to={href}
        className={`flex items-center py-2.5 px-4 hover:bg-[#333] transition ${
          isActive ? 'bg-[#333] border-l-2 border-[#e50914]' : ''
        }`}
      >
        <FontAwesomeIcon icon={icon} className="text-[#b3b3b3]" />
        <span
          className={`text-[#b3b3b3] text-base font-medium leading-tight ml-4 text-nowrap ${
            isCollapsed ? 'hidden' : 'block'
          }`}
        >
          {label}
        </span>
      </Link>
    </li>
  );
};

export default SidebarItem