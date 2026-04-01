import { useNavigate, Link } from 'react-router-dom';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { faTrash, faCircleInfo } from '@fortawesome/free-solid-svg-icons';
import { useOutletContext } from 'react-router-dom';


function UserTable() {
    const navigate = useNavigate();
    const { users, isLoading, error } = useOutletContext();

    if (error) return <p>An error occurred - {error.message}</p>;
    if (isLoading) return <p>Loading...</p>;

    return (
        <div className="bg-zinc-900 rounded-lg shadow-lg p-8 my-8 mx-auto max-w-4xl border border-zinc-800">
            <table className="w-full border-separate border-spacing-0">
                <thead>
                    <tr className="bg-zinc-950">
                        <th className="text-left py-3 px-2 rounded-tl-lg text-zinc-300">First Name</th>
                        <th className="text-left py-3 px-2 text-zinc-300">Last Name</th>
                        <th className="text-left py-3 px-2 text-zinc-300">Email</th>
                        <th className="text-center py-3 px-2 text-zinc-300">Actions</th>
                        <th className="py-3 px-2 rounded-tr-lg"></th>
                    </tr>
                </thead>
                <tbody>
                    {
                        users.map((user, idx) => {
                            return (
                                <tr key={user._id} className={idx % 2 === 0 ? 'bg-zinc-800' : 'bg-zinc-900'}>
                                    <td className="py-2.5 px-2 border-b border-zinc-800 text-white">{user.firstName}</td>
                                    <td className="py-2.5 px-2 border-b border-zinc-800 text-white">{user.lastName}</td>
                                    <td className="py-2.5 px-2 border-b border-zinc-800 text-zinc-300">{user.email}</td>
                                    <td className="py-2.5 px-2 border-b border-zinc-800 text-center">
                                        <button onClick={() => navigate(`/admin/users/${user._id}/delete`)} className="mr-2 py-1 px-2.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded font-bold text-sm cursor-pointer transition" title="Delete">
                                            <FontAwesomeIcon icon={faTrash} />
                                        </button>
                                        <button onClick={() => navigate(`/admin/users/${user._id}/details`)} className="py-1 px-2.5 bg-zinc-800 hover:bg-zinc-700 text-zinc-300 border border-zinc-700 rounded font-bold text-sm cursor-pointer transition" title="Details">
                                            <FontAwesomeIcon icon={faCircleInfo} />
                                        </button>
                                    </td>
                                    <td className="py-2.5 px-2 border-b border-zinc-800"></td>
                                </tr>
                            );
                        })
                    }
                </tbody>
            </table>
        </div>
    )
}

export default UserTable