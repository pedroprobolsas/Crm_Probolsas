import { format } from 'date-fns';
import { es } from 'date-fns/locale';
import {
  Phone,
  Mail,
  Users,
  HelpCircle,
  FileText,
  Clock,
  Flag,
  MessageCircle,
  AlertCircle,
  CheckCircle,
  XCircle,
  Edit2
} from 'lucide-react';
import type { ClientInteraction } from '../lib/types';

interface ClientTimelineProps {
  interactions?: (ClientInteraction & { agent: { name: string } })[];
  onEdit?: (interaction: ClientInteraction & { agent: { name: string } }) => void;
}

const interactionIcons = {
  call: Phone,
  email: Mail,
  visit: Users,
  consultation: HelpCircle,
};

const priorityColors = {
  low: 'bg-gray-100 text-gray-800',
  medium: 'bg-yellow-100 text-yellow-800',
  high: 'bg-red-100 text-red-800',
};

const statusIcons = {
  pending: AlertCircle,
  completed: CheckCircle,
  cancelled: XCircle,
};

const statusColors = {
  pending: 'text-yellow-500',
  completed: 'text-green-500',
  cancelled: 'text-red-500',
};

export function ClientTimeline({ interactions = [], onEdit }: ClientTimelineProps) {
  if (!interactions || interactions.length === 0) {
    return (
      <div className="text-center py-8 text-gray-500">
        <MessageCircle className="w-12 h-12 mx-auto mb-4 opacity-50" />
        <p>No hay interacciones registradas</p>
      </div>
    );
  }

  return (
    <div className="flow-root">
      <ul role="list" className="-mb-8">
        {interactions.map((interaction, index) => {
          const Icon = interactionIcons[interaction.type];
          const StatusIcon = statusIcons[interaction.status];
          
          return (
            <li key={interaction.id}>
              <div className="relative pb-8">
                {index !== interactions.length - 1 ? (
                  <span
                    className="absolute left-4 top-4 -ml-px h-full w-0.5 bg-gray-200"
                    aria-hidden="true"
                  />
                ) : null}
                <div className="relative flex space-x-3">
                  <div>
                    <span className="h-8 w-8 rounded-full flex items-center justify-center ring-8 ring-white bg-blue-100">
                      <Icon className="h-5 w-5 text-blue-600" />
                    </span>
                  </div>
                  <div className="flex min-w-0 flex-1 justify-between space-x-4">
                    <div className="relative">
                      {onEdit && (
                        <button
                          onClick={() => onEdit(interaction)}
                          className="absolute -right-8 top-0 p-1 text-gray-400 hover:text-gray-600"
                          title="Editar interacción"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                      )}
                      <p className="text-sm text-gray-600">
                        {interaction.notes}
                        <span className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${priorityColors[interaction.priority]}`}>
                          {interaction.priority}
                        </span>
                        <span className={`ml-2 inline-flex items-center ${statusColors[interaction.status]}`}>
                          <StatusIcon className="w-4 h-4" />
                        </span>
                      </p>
                      {interaction.next_action && (
                        <div className="mt-2 flex items-center text-sm text-gray-500">
                          <Flag className="w-4 h-4 mr-1" />
                          <span>Siguiente acción: {interaction.next_action}</span>
                          {interaction.next_action_date && (
                            <>
                              <Clock className="w-4 h-4 ml-2 mr-1" />
                              <span>
                                {format(new Date(interaction.next_action_date), "d 'de' MMMM", { locale: es })}
                              </span>
                            </>
                          )}
                        </div>
                      )}
                      {interaction.attachments && interaction.attachments.length > 0 && (
                        <div className="mt-2 space-y-1">
                          {interaction.attachments.map((file, fileIndex) => (
                            <a
                              key={fileIndex}
                              href={file.url}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="inline-flex items-center text-sm text-blue-600 hover:text-blue-800"
                            >
                              <FileText className="w-4 h-4 mr-1" />
                              {file.name}
                            </a>
                          ))}
                        </div>
                      )}
                    </div>
                    <div className="whitespace-nowrap text-right text-sm text-gray-500">
                      <time dateTime={interaction.date}>
                        {format(new Date(interaction.date), "d 'de' MMMM 'a las' HH:mm", { locale: es })}
                      </time>
                      <div className="text-xs text-gray-400">{interaction.agent.name}</div>
                    </div>
                  </div>
                </div>
              </div>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
